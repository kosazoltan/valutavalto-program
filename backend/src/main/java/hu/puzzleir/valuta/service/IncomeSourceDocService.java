package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.document.IncomeProofEmailRequest;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * FS-7: 10M+ jövedelemforrás-doksi stream-through email. ZERO-PERSISTENCE:
 * a kép bájtjai kizárólag e metódusok stack/heap-jén élnek — SEMMILYEN repository,
 * fájlrendszer vagy log nem kaphatja meg őket. Ide dokumentum-repository injektálása TILOS.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class IncomeSourceDocService {

    public static final String RECIPIENTS_PARAM_PREFIX = "INCOME_PROOF_DOC_RECIPIENTS.";
    private static final Set<String> ALLOWED_MIME = Set.of("image/jpeg", "image/png", "application/pdf");
    private static final Pattern EMAIL_RX = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    private final JavaMailSender mailSender;
    private final SystemParameterService systemParameterService;
    private final AuditLogService auditLogService;
    private final AmlService amlService;
    private final ValueBandService valueBandService;

    @Value("${income.proof.max-size-bytes:10485760}")
    private long maxSizeBytes;

    @Value("${spring.mail.username:noraautomatizalas@gmail.com}")
    private String fromAddress;

    public boolean isRequired(String customerId, BigDecimal hufAmount, String currencyCode) {
        int type = amlService.classifyTransaction(customerId, hufAmount, currencyCode);
        return type == 5 || type == 6; // hasforint >= incomeProofLimitHuf (AmlService:576-583)
    }

    public BigDecimal thresholdHuf() {
        return ValueBandService.resolve(valueBandService).incomeProofLimitHuf();
    }

    /** @return elküldött címzettek száma. Hibaágon ValidationException — SOHA csendes elnyelés. */
    public int sendIncomeProofDocument(IncomeProofEmailRequest req) {
        byte[] bytes = null;
        List<String> recipients = List.of();
        try {
            if (req.getMimeType() == null || !ALLOWED_MIME.contains(req.getMimeType())) {
                throw new ValidationException("Nem engedélyezett fájltípus: " + req.getMimeType());
            }
            recipients = resolveRecipients(SecurityUtils.getCurrentCompanyId());
            try {
                bytes = Base64.getDecoder().decode(req.getImageBase64());
            } catch (IllegalArgumentException e) {
                throw new ValidationException("Érvénytelen kép-kódolás (base64)!");
            }
            if (bytes.length == 0 || bytes.length > maxSizeBytes) {
                throw new ValidationException("A dokumentum mérete érvénytelen (max "
                        + maxSizeBytes + " bájt)!");
            }
            sendMime(recipients, req, bytes);
            auditLogService.log("INCOME_PROOF_DOC_EMAILED", factMessage(req, bytes.length,
                    recipients.size(), "SIKERES"), req.getTransactionRef());
            return recipients.size();
        } catch (ValidationException ve) {
            auditLogService.log("INCOME_PROOF_DOC_EMAIL_FAILED", factMessage(req,
                    bytes == null ? 0 : bytes.length, recipients.size(),
                    "HIBA: " + ve.getMessage()), req.getTransactionRef());
            throw ve;
        } catch (Exception e) {
            log.warn("FS-7 jövedelemforrás-email küldés sikertelen: txRef={}, hiba={}",
                    req.getTransactionRef(), e.getMessage()); // SOHA nem logoljuk a payloadot
            auditLogService.log("INCOME_PROOF_DOC_EMAIL_FAILED", factMessage(req,
                    bytes == null ? 0 : bytes.length, recipients.size(),
                    "HIBA: " + e.getMessage()), req.getTransactionRef());
            throw new ValidationException("A jövedelemforrás-igazolás email-küldése sikertelen — "
                    + "próbáld újra!");
        } finally {
            if (bytes != null) {
                Arrays.fill(bytes, (byte) 0); // defenzív heap-wipe
            }
        }
    }

    private void sendMime(List<String> recipients, IncomeProofEmailRequest req, byte[] bytes)
            throws Exception {
        MimeMessage msg = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(msg, true, "UTF-8"); // multipart=true
        helper.setFrom(fromAddress);
        helper.setTo(recipients.toArray(String[]::new));
        helper.setSubject("[Valutaváltó][FS-7] Jövedelemforrás-igazolás — bizonylat: "
                + safe(req.getTransactionRef()));
        helper.setText(buildBody(req), false);
        String ext = "application/pdf".equals(req.getMimeType()) ? "pdf"
                : ("image/png".equals(req.getMimeType()) ? "png" : "jpg");
        helper.addAttachment("jovedelemforras-igazolas." + ext,
                new ByteArrayResource(bytes), req.getMimeType());
        mailSender.send(msg);
    }

    private List<String> resolveRecipients(UUID companyId) {
        String raw = systemParameterService.getValue(RECIPIENTS_PARAM_PREFIX + companyId, "");
        List<String> list = Arrays.stream(raw.split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).toList();
        if (list.isEmpty()) {
            throw new ValidationException("Nincsenek beállítva jövedelemforrás-igazolás címzettek "
                    + "ehhez a céghez — a compliance beállításokban rögzítendő!");
        }
        list.forEach(e -> {
            if (!EMAIL_RX.matcher(e).matches()) {
                throw new ValidationException("Érvénytelen címzett email: " + e);
            }
        });
        return list;
    }

    private String factMessage(IncomeProofEmailRequest req, int size, int recipients, String outcome) {
        return "Jövedelemforrás-doksi email — worker=" + currentWorkerCodeOrUnknown()
                + ", tx=" + safe(req.getTransactionRef()) + ", ügyfél=" + safe(req.getCustomerName())
                + ", összeg=" + req.getHufAmount() + " Ft, méret=" + size + " bájt, címzettek="
                + recipients + ", eredmény=" + safe(outcome); // tartalom/bájt SOHA
    }

    private String currentWorkerCodeOrUnknown() {
        try { return SecurityUtils.getCurrentWorkerCode(); } catch (Exception e) { return "ismeretlen"; }
    }

    private String buildBody(IncomeProofEmailRequest req) {
        return "Tisztelt Compliance Csoport!\n\n"
                + "A pénztáros jövedelemforrás-igazoló dokumentumot töltött fel egy 10M+ HUF "
                + "értékű valutaváltási tranzakcióhoz.\n\n"
                + "Bizonylat referenciája: " + safe(req.getTransactionRef()) + "\n"
                + "Ügyfél neve: " + safe(req.getCustomerName()) + "\n"
                + "Tranzakció összege (HUF): " + req.getHufAmount() + "\n"
                + "Dátum: " + LocalDate.now() + "\n\n"
                + "A dokumentum csatolmányként került beküldésre. A kép tartalma kizárólag "
                + "memórián keresztül folyt át — semmilyen perzisztens tárolóba nem került.\n\n"
                + "Üdvözlettel,\nValutaváltó rendszer";
    }

    private static String safe(String s) { return s == null ? "-" : s.replaceAll("[\\r\\n]", " "); }
}

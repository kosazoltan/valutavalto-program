package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Napkönyv (daily transaction journal) PDF service — legacy NAPKONYV (33K, 65f) parity.
 *
 * <p>v2.5.68 Sprint A P2.4: napi forgalmi napló — minden tranzakció kronologikusan
 * listázva + valutánkénti és típusonkénti összesítés a lap alján. KÜLÖNBÖZIK a
 * {@link DailyClosingPdfService}-től, ami napzárás (cash count + reconciliation).</p>
 *
 * <p>Multi-tenant: a branch.company FK kötelező — a controller @PreAuthorize-zal
 * szűri az illetékességet, plus a JPQL `t.branch.id = :branchId` természeténél fogva
 * tenant-skópolt (a branch.id egyedi globally, FK constraint).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DailyJournalService {

    @PersistenceContext
    private EntityManager entityManager;

    private final BranchRepository branchRepository;

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float MARGIN = 40f;
    private static final float FONT_SIZE_HEADER = 12f;
    private static final float FONT_SIZE_BODY = 9f;
    private static final float LINE_HEIGHT = 12f;

    private static final DecimalFormat AMOUNT_FORMAT;
    private static final DecimalFormat RATE_FORMAT;
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    static {
        DecimalFormatSymbols sym = new DecimalFormatSymbols(Locale.forLanguageTag("hu-HU"));
        sym.setGroupingSeparator(' ');
        AMOUNT_FORMAT = new DecimalFormat("#,##0", sym);
        RATE_FORMAT = new DecimalFormat("#,##0.00", sym);
    }

    /**
     * Generálja a napi forgalmi naplót PDF-ben az adott iroda + nap kombinációra.
     */
    public byte[] generatePdf(UUID branchId, LocalDate date) throws IOException {
        if (branchId == null || date == null) {
            throw new IllegalArgumentException("branchId és date kötelező");
        }

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new IllegalArgumentException("Nem létező branch: " + branchId));

        // Copilot P0 #705 fix: multi-tenant IDOR védelem — a controller @PreAuthorize
        // role-szinten véd, de a branchId URL paraméter user-controlled. Itt verifikáljuk,
        // hogy a branch a jelenlegi cég-hez tartozik (defense-in-depth).
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() == null || !branch.getCompany().getId().equals(currentCompanyId)) {
            log.warn("Cross-tenant access blocked: branchId={}, currentCompanyId={}, branchCompanyId={}",
                    branchId, currentCompanyId,
                    branch.getCompany() != null ? branch.getCompany().getId() : null);
            throw new ValidationException("A megadott branch nem tartozik a jelenlegi céghez (cross-tenant access blocked)");
        }

        List<Transaction> transactions = fetchTransactions(branchId, date);
        Map<String, BigDecimal> currencySummary = aggregateByCurrency(transactions);
        Map<TransactionType, Integer> typeSummary = aggregateByType(transactions);

        return renderPdf(branch, date, transactions, currencySummary, typeSummary);
    }

    @SuppressWarnings("unchecked")
    private List<Transaction> fetchTransactions(UUID branchId, LocalDate date) {
        return entityManager.createQuery(
                "SELECT t FROM Transaction t " +
                        "LEFT JOIN FETCH t.currency " +
                        "LEFT JOIN FETCH t.worker " +
                        "WHERE t.branch.id = :branchId " +
                        "AND t.transactionDate = :date " +
                        "AND t.status = :status " +
                        "AND t.financialEffective = TRUE " +
                        "ORDER BY t.transactionTime ASC, t.receiptNumber ASC",
                Transaction.class)
                .setParameter("branchId", branchId)
                .setParameter("date", date)
                .setParameter("status", TransactionStatus.COMPLETED)
                .getResultList();
    }

    private Map<String, BigDecimal> aggregateByCurrency(List<Transaction> txs) {
        Map<String, BigDecimal> map = new HashMap<>();
        for (Transaction t : txs) {
            if (t.getCurrency() == null) continue;
            String code = t.getCurrency().getCode();
            BigDecimal hufAmount = t.getHufAmount() != null ? t.getHufAmount() : BigDecimal.ZERO;
            map.merge(code, hufAmount, BigDecimal::add);
        }
        return map;
    }

    private Map<TransactionType, Integer> aggregateByType(List<Transaction> txs) {
        Map<TransactionType, Integer> map = new HashMap<>();
        for (Transaction t : txs) {
            map.merge(t.getTransactionType(), 1, Integer::sum);
        }
        return map;
    }

    private byte[] renderPdf(Branch branch, LocalDate date, List<Transaction> txs,
                              Map<String, BigDecimal> currencySummary,
                              Map<TransactionType, Integer> typeSummary) throws IOException {
        try (PDDocument doc = new PDDocument();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);

            try (PDPageContentStream content = new PDPageContentStream(doc, page)) {
                float y = PAGE_HEIGHT - MARGIN;

                // === Fejléc ===
                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), FONT_SIZE_HEADER);
                content.newLineAtOffset(MARGIN, y);
                content.showText("NAPKONYV — Napi forgalmi naplo");
                content.endText();
                y -= LINE_HEIGHT * 1.5f;

                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), FONT_SIZE_BODY);
                content.newLineAtOffset(MARGIN, y);
                content.showText("Iroda: " + safeText(branch.getCode() + " - " + branch.getName()));
                content.endText();
                y -= LINE_HEIGHT;

                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), FONT_SIZE_BODY);
                content.newLineAtOffset(MARGIN, y);
                content.showText("Datum: " + DATE_FORMAT.format(date));
                content.endText();
                y -= LINE_HEIGHT;

                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), FONT_SIZE_BODY);
                content.newLineAtOffset(MARGIN, y);
                content.showText("Tranzakciok szama: " + txs.size());
                content.endText();
                y -= LINE_HEIGHT * 2;

                // === Tranzakció lista fejléc ===
                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), FONT_SIZE_BODY);
                content.newLineAtOffset(MARGIN, y);
                content.showText("Ido   Bizonylat   Tipus       Valuta  Mennyiseg     HUF egyenertek");
                content.endText();
                y -= LINE_HEIGHT;

                // === Tranzakciók ===
                // Egy A4 lapra ~50-60 tranzakció fér. Ha több → "...és X további tranzakció"
                // sor + az összesítés ugyanezen oldalon marad. (Copilot #705 fix: a régi
                // try-with-resources break-pattern bugos volt — page-flow korrekt: explicit
                // cap, NEM félbeszakítás.)
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), FONT_SIZE_BODY);
                final float MIN_Y_FOR_TX = MARGIN + 120f;  // Hely a footer-aggregátorra
                int rendered = 0;
                for (Transaction t : txs) {
                    if (y < MIN_Y_FOR_TX) break;
                    renderTransactionRow(content, t, y);
                    y -= LINE_HEIGHT;
                    rendered++;
                }
                if (rendered < txs.size()) {
                    int remaining = txs.size() - rendered;
                    content.beginText();
                    content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_OBLIQUE), FONT_SIZE_BODY);
                    content.newLineAtOffset(MARGIN, y);
                    content.showText("...es meg " + remaining + " tranzakcio (multi-page render TODO)");
                    content.endText();
                    y -= LINE_HEIGHT;
                }

                y -= LINE_HEIGHT;

                // === Összesítés valutánként ===
                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), FONT_SIZE_BODY);
                content.newLineAtOffset(MARGIN, y);
                content.showText("OSSZESITES VALUTANKENT (HUF egyenertek):");
                content.endText();
                y -= LINE_HEIGHT;

                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), FONT_SIZE_BODY);
                for (var entry : currencySummary.entrySet()) {
                    content.beginText();
                    content.newLineAtOffset(MARGIN + 20, y);
                    content.showText("  " + entry.getKey() + ": " + AMOUNT_FORMAT.format(entry.getValue()) + " Ft");
                    content.endText();
                    y -= LINE_HEIGHT;
                }

                y -= LINE_HEIGHT;

                // === Összesítés típusonként ===
                content.beginText();
                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), FONT_SIZE_BODY);
                content.newLineAtOffset(MARGIN, y);
                content.showText("OSSZESITES TIPUSONKENT:");
                content.endText();
                y -= LINE_HEIGHT;

                content.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), FONT_SIZE_BODY);
                for (var entry : typeSummary.entrySet()) {
                    content.beginText();
                    content.newLineAtOffset(MARGIN + 20, y);
                    content.showText("  " + entry.getKey().name() + ": " + entry.getValue() + " db");
                    content.endText();
                    y -= LINE_HEIGHT;
                }
            }

            doc.save(baos);
            return baos.toByteArray();
        }
    }

    private void renderTransactionRow(PDPageContentStream content, Transaction t, float y) throws IOException {
        String time = t.getTransactionTime() != null
                ? TIME_FORMAT.format(t.getTransactionTime()) : "?????";
        String receipt = safeText(t.getReceiptNumber());
        String type = t.getTransactionType().name();
        String currency = t.getCurrency() != null ? t.getCurrency().getCode() : "???";
        String currAmt = t.getCurrencyAmount() != null
                ? RATE_FORMAT.format(t.getCurrencyAmount()) : "0";
        String hufAmt = t.getHufAmount() != null
                ? AMOUNT_FORMAT.format(t.getHufAmount()) : "0";

        content.beginText();
        content.newLineAtOffset(MARGIN, y);
        content.showText(String.format("%-6s%-12s%-12s%-7s%12s   %12s Ft",
                time, truncate(receipt, 11), truncate(type, 11), currency, currAmt, hufAmt));
        content.endText();
    }

    /** PDF szöveg-biztos string (ékezet → ASCII fallback PDF-mentes szövegre). */
    private static String safeText(String s) {
        if (s == null) return "";
        // PDType1Font Standard14Fonts WinAnsi encoding-et használ, magyar ékezet OK,
        // de extra-Unicode (pl. → ¶) NEM. Itt csak null-safe.
        return s;
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) : s;
    }
}

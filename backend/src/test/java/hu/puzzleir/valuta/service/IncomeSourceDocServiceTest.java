package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.document.IncomeProofEmailRequest;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import jakarta.mail.internet.MimeMultipart;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Base64;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class IncomeSourceDocServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final String VALID_B64;

    static {
        // 1024 bájtnyi 0x41 — érvényes base64, dekódolva < maxSizeBytes
        byte[] data = new byte[1024];
        Arrays.fill(data, (byte) 0x41);
        VALID_B64 = Base64.getEncoder().encodeToString(data);
    }

    @Mock private JavaMailSender mailSender;
    @Mock private SystemParameterService systemParameterService;
    @Mock private AuditLogService auditLogService;
    @Mock private AmlService amlService;
    @Mock private ValueBandService valueBandService;

    @InjectMocks private IncomeSourceDocService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "maxSizeBytes", 10485760L);
        ReflectionTestUtils.setField(service, "fromAddress", "test@valuta.local");
    }

    private IncomeProofEmailRequest req(String mime, String b64) {
        return IncomeProofEmailRequest.builder()
                .imageBase64(b64)
                .mimeType(mime)
                .transactionRef("TX-001")
                .customerName("Teszt Ügyfél")
                .hufAmount(new BigDecimal("12000000"))
                .build();
    }

    private void stubRecipients(String raw) {
        when(systemParameterService.getCompanyValue(
                eq(IncomeSourceDocService.RECIPIENTS_PARAM_KEY), eq(COMPANY_ID), anyString()))
                .thenReturn(raw);
    }

    @Test
    void send_success_sendsMimeWithAttachment_andAuditsFactOnly() throws Exception {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-1");
            stubRecipients("compliance@valuta.local, audit@valuta.local");
            MimeMessage real = new MimeMessage((Session) null);
            when(mailSender.createMimeMessage()).thenReturn(real);

            int sent = service.sendIncomeProofDocument(req("image/jpeg", VALID_B64));

            assertThat(sent).isEqualTo(2);
            ArgumentCaptor<MimeMessage> cap = ArgumentCaptor.forClass(MimeMessage.class);
            verify(mailSender).send(cap.capture());
            // saveChanges() materializálja a Content-Type fejlécet — mentetlen MimeMessage-nél
            // isMimeType() hamisat adna (JavaMail csak saveChanges után számolja a fejlécet).
            MimeMessage captured = cap.getValue();
            captured.saveChanges();
            assertThat(captured.isMimeType("multipart/*")).isTrue();
            MimeMultipart mp = (MimeMultipart) captured.getContent();
            assertThat(mp.getCount()).isGreaterThanOrEqualTo(2);
            assertThat(mp.getBodyPart(1).getFileName()).isEqualTo("jovedelemforras-igazolas.jpg");
            // audit EMAILED hívatás — üzenet NEM tartalmazhat base64 részletet
            verify(auditLogService).log(eq("INCOME_PROOF_DOC_EMAILED"), anyString(), eq("TX-001"));
            // címzettek feloldása egyetlen systemParameter hívás (verifyNoMoreInteractions előtt)
            verify(systemParameterService).getCompanyValue(
                    eq(IncomeSourceDocService.RECIPIENTS_PARAM_KEY), eq(COMPANY_ID), anyString());
            // zero extra collaborators
            verifyNoMoreInteractions(systemParameterService, auditLogService, amlService,
                    valueBandService);
        }
    }

    @Test
    void send_noRecipientsConfigured_throwsValidation_andNeverSends() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            stubRecipients("");

            assertThatThrownBy(() -> service.sendIncomeProofDocument(req("image/jpeg", VALID_B64)))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("címzettek");

            verify(mailSender, never()).send(any(MimeMessage.class));
            // fail-closed: audit FAILED recorded
            verify(auditLogService).log(eq("INCOME_PROOF_DOC_EMAIL_FAILED"), anyString(),
                    eq("TX-001"));
        }
    }

    @Test
    void send_smtpThrows_auditsFailed_andPropagatesValidationException() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-1");
            stubRecipients("compliance@valuta.local");
            MimeMessage real = new MimeMessage((Session) null);
            when(mailSender.createMimeMessage()).thenReturn(real);
            doThrow(new RuntimeException("SMTP connection refused"))
                    .when(mailSender).send(any(MimeMessage.class));

            assertThatThrownBy(() -> service.sendIncomeProofDocument(req("image/jpeg", VALID_B64)))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("sikertelen");

            verify(auditLogService).log(eq("INCOME_PROOF_DOC_EMAIL_FAILED"), anyString(),
                    eq("TX-001"));
        }
    }

    @Test
    void send_oversizedPayload_rejected() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-1");
            stubRecipients("compliance@valuta.local");
            // maxSizeBytes=10MB; 11MB payload
            byte[] big = new byte[11 * 1024 * 1024 + 1];
            Arrays.fill(big, (byte) 0x42);
            String bigB64 = Base64.getEncoder().encodeToString(big);

            assertThatThrownBy(() -> service.sendIncomeProofDocument(req("image/jpeg", bigB64)))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("mérete");

            verify(mailSender, never()).send(any(MimeMessage.class));
            verify(auditLogService).log(eq("INCOME_PROOF_DOC_EMAIL_FAILED"), anyString(),
                    eq("TX-001"));
        }
    }

    @Test
    void send_invalidMime_rejected() {
        assertThatThrownBy(() -> service.sendIncomeProofDocument(req("text/html", VALID_B64)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("fájltípus");

        verify(mailSender, never()).send(any(MimeMessage.class));
        verify(auditLogService).log(eq("INCOME_PROOF_DOC_EMAIL_FAILED"), anyString(),
                eq("TX-001"));
    }

    @Test
    void required_delegatesToClassifyTransaction() {
        BigDecimal amount = new BigDecimal("12000000");

        // type 5 → required true
        when(amlService.classifyTransaction("C1", amount, "EUR")).thenReturn(5);
        assertThat(service.isRequired("C1", amount, "EUR")).isTrue();

        // type 4 → required false
        when(amlService.classifyTransaction("C1", amount, "EUR")).thenReturn(4);
        assertThat(service.isRequired("C1", amount, "EUR")).isFalse();

        // type 6 → required true
        when(amlService.classifyTransaction("C1", amount, "EUR")).thenReturn(6);
        assertThat(service.isRequired("C1", amount, "EUR")).isTrue();
    }
}

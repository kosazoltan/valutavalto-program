package hu.puzzleir.valuta.errorlog;

import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.PlatformTransactionManager;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ErrorMailerServiceTest {

    @Mock private ErrorLogRepository errorLogRepo;
    @Mock private JavaMailSender mailSender;
    @Mock private PlatformTransactionManager transactionManager;
    @InjectMocks private ErrorMailerService service;

    @BeforeEach
    void setUp() {
        when(errorLogRepo.findByFingerprint(any())).thenReturn(Optional.empty());
        when(errorLogRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void sendErrorReport_blankSecret_throwsIllegalState_andNeverSendsMail() {
        ReflectionTestUtils.setField(service, "hmacSecret", "");
        var req = ErrorReportRequest.builder()
            .errorType("api_error")
            .message("x")
            .stack("y")
            .build();

        assertThatThrownBy(() -> service.sendErrorReport(req))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("errorlog.hmac.secret");

        verify(errorLogRepo).save(any());
        verify(mailSender, never()).send(any(MimeMessage.class));
    }

    @Test
    void sendErrorReport_redactsPiiInEmailHtml() throws Exception {
        ReflectionTestUtils.setField(service, "hmacSecret", "test-secret");
        MimeMessage real = new MimeMessage((Session) null);
        when(mailSender.createMimeMessage()).thenReturn(real);

        String iban = "HU42117730161111101800000000";
        String pan = "4111111111111111";
        String jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0VXNlciJ9.abcDEFghijkLMNOP12345";
        var req = ErrorReportRequest.builder()
            .errorType("api_error")
            .message("IBAN a hibában: " + iban)
            .stack("PAN=" + pan + " token=" + jwt)
            .build();

        service.sendErrorReport(req);

        ArgumentCaptor<MimeMessage> cap = ArgumentCaptor.forClass(MimeMessage.class);
        verify(mailSender).send(cap.capture());
        String html = (String) cap.getValue().getContent();
        assertThat(html).contains("[PAN]").contains("[JWT]").contains("[IBAN]");
        assertThat(html)
            .doesNotContain(pan)
            .doesNotContain(iban)
            .doesNotContain(jwt);
    }
}

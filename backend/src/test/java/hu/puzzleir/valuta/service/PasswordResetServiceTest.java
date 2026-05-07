package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.PasswordResetToken;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.PasswordResetTokenRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@link PasswordResetService} egysegtesztek.
 *
 * <p>Audit P1.8 (2026-05-03): production email kikuldes regresszio-vedelem +
 * anti-enumeration garancia.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PasswordResetService — forgot/reset password flow + email kikuldes (P1.8)")
class PasswordResetServiceTest {

    @Mock private WorkerRepository workerRepository;
    @Mock private PasswordResetTokenRepository resetTokenRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private EmailNotificationService emailNotificationService;

    @InjectMocks private PasswordResetService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "frontendBaseUrl", "https://excvaluta.com");
    }

    @Test
    @DisplayName("requestForgotPassword: ismeretlen email -> NEM kuldunk emailt (anti-enumeration)")
    void unknownEmail_doesNotSendEmail() {
        when(workerRepository.findByEmail("unknown@example.com")).thenReturn(Optional.empty());

        String token = service.requestForgotPassword("unknown@example.com");

        assertThat(token).isNull();
        verify(resetTokenRepository, never()).save(any(PasswordResetToken.class));
        verify(emailNotificationService, never()).sendEmail(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("requestForgotPassword: inaktiv worker -> NEM kuldunk emailt")
    void inactiveWorker_doesNotSendEmail() {
        Worker inactive = Worker.builder().id(1L).email("inactive@example.com").active(false).build();
        when(workerRepository.findByEmail("inactive@example.com")).thenReturn(Optional.of(inactive));

        String token = service.requestForgotPassword("inactive@example.com");

        assertThat(token).isNull();
        verify(resetTokenRepository, never()).save(any(PasswordResetToken.class));
        verify(emailNotificationService, never()).sendEmail(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("requestForgotPassword: aktiv worker -> emailt kuldunk a reset linkkel")
    void activeWorker_sendsEmailWithResetLink() {
        Worker worker = Worker.builder()
                .id(42L)
                .name("Teszt Elek")
                .email("test@example.com")
                .active(true)
                .build();
        when(workerRepository.findByEmail("test@example.com")).thenReturn(Optional.of(worker));

        String token = service.requestForgotPassword("test@example.com");

        assertThat(token).isNotBlank();
        verify(resetTokenRepository).save(any(PasswordResetToken.class));

        ArgumentCaptor<String> toCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> subjectCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> bodyCaptor = ArgumentCaptor.forClass(String.class);
        verify(emailNotificationService, times(1))
                .sendEmail(toCaptor.capture(), subjectCaptor.capture(), bodyCaptor.capture());

        assertThat(toCaptor.getValue()).isEqualTo("test@example.com");
        assertThat(subjectCaptor.getValue()).contains("Jelszo");
        // Reset link tartalmazza a frontend URL-t es a tokent (URL-encoded)
        assertThat(bodyCaptor.getValue())
                .contains("https://excvaluta.com/reset-password?token=")
                .contains("Teszt Elek");
    }

    @Test
    @DisplayName("requestForgotPassword: aktiv worker email nelkul -> NEM kuldunk emailt, de token generalva")
    void activeWorkerWithoutEmail_doesNotSendButGeneratesToken() {
        Worker worker = Worker.builder()
                .id(7L)
                .name("Email Nelkul")
                .email(null)
                .active(true)
                .build();
        // findByEmail-bol jott vissza, de a worker.email null -> edge case (DB inkonzisztencia)
        when(workerRepository.findByEmail("ghost@example.com")).thenReturn(Optional.of(worker));

        String token = service.requestForgotPassword("ghost@example.com");

        // Token generalt (a flow folytatodik), de email NEM ment ki
        assertThat(token).isNotBlank();
        verify(resetTokenRepository).save(any(PasswordResetToken.class));
        verify(emailNotificationService, never()).sendEmail(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("requestForgotPassword: blank email -> NEM kuldunk emailt, NEM tobbet")
    void blankEmail_returnsNullAndDoesNothing() {
        String token = service.requestForgotPassword("  ");

        assertThat(token).isNull();
        verify(workerRepository, never()).findByEmail(anyString());
        verify(resetTokenRepository, never()).save(any(PasswordResetToken.class));
        verify(emailNotificationService, never()).sendEmail(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("requestForgotPassword: null email -> NEM kuldunk emailt, NEM tobbet")
    void nullEmail_returnsNullAndDoesNothing() {
        String token = service.requestForgotPassword(null);

        assertThat(token).isNull();
        verify(workerRepository, never()).findByEmail(anyString());
        verify(resetTokenRepository, never()).save(any(PasswordResetToken.class));
        verify(emailNotificationService, never()).sendEmail(anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("requestForgotPassword: email lowercase normalizalva")
    void emailIsNormalizedToLowercase() {
        Worker worker = Worker.builder()
                .id(99L)
                .name("Mixed Case")
                .email("mixed@example.com")
                .active(true)
                .build();
        when(workerRepository.findByEmail("mixed@example.com")).thenReturn(Optional.of(worker));

        service.requestForgotPassword("  Mixed@Example.COM  ");

        verify(workerRepository).findByEmail("mixed@example.com");
        verify(emailNotificationService).sendEmail(eqIgnoreNull("mixed@example.com"), anyString(), anyString());
    }

    @Test
    @DisplayName("resetPassword: ervenytelen token -> ValidationException")
    void invalidToken_throwsValidationException() {
        when(resetTokenRepository.findByTokenHashAndUsedAtIsNull(anyString())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.resetPassword("not-a-real-token", "newPass123"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Ervenytelen");
        verify(workerRepository, never()).save(any(Worker.class));
    }

    @Test
    @DisplayName("resetPassword: ervenyes token -> jelszo frissitese + worker mentese")
    void validToken_resetsPassword() {
        Worker worker = Worker.builder()
                .id(11L)
                .name("Reset Teszt")
                .email("reset@example.com")
                .active(true)
                .build();
        PasswordResetToken resetToken = PasswordResetToken.builder()
                .workerId(11L)
                .expiresAt(Instant.now().plusSeconds(60))
                .build();
        when(resetTokenRepository.findByTokenHashAndUsedAtIsNull(anyString())).thenReturn(Optional.of(resetToken));
        when(workerRepository.findById(11L)).thenReturn(Optional.of(worker));
        when(passwordEncoder.encode("newPassword123")).thenReturn("$2a$encoded$");

        service.resetPassword("valid-reset-token", "newPassword123");

        assertThat(resetToken.getUsedAt()).isNotNull();
        verify(resetTokenRepository).save(resetToken);
        verify(passwordEncoder).encode("newPassword123");
        verify(workerRepository).save(worker);
        assertThat(worker.getPasswordHash()).isEqualTo("$2a$encoded$");
        assertThat(worker.getPasswordChangedAt()).isNotNull();
    }

    @Test
    @DisplayName("resetPassword: token egyszeri hasznalat (consume-after-use)")
    void resetPassword_tokenConsumedAfterUse() {
        Worker worker = Worker.builder()
                .id(13L)
                .name("Egyszer Hasznal")
                .email("consume@example.com")
                .active(true)
                .build();
        PasswordResetToken resetToken = PasswordResetToken.builder()
                .workerId(13L)
                .expiresAt(Instant.now().plusSeconds(60))
                .build();
        when(resetTokenRepository.findByTokenHashAndUsedAtIsNull(anyString()))
                .thenReturn(Optional.of(resetToken))
                .thenReturn(Optional.empty());
        when(workerRepository.findById(13L)).thenReturn(Optional.of(worker));
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$x$");

        service.resetPassword("consume-token", "first123");

        assertThatThrownBy(() -> service.resetPassword("consume-token", "second456"))
                .isInstanceOf(ValidationException.class);
    }

    // --- helpers ---

    private static String eqIgnoreNull(String value) {
        // Kisegitő helper hogy ne kelljen importalni az ArgumentMatchers-eq()-t a tobbi mellett
        return org.mockito.ArgumentMatchers.eq(value);
    }

    private static <T> T any(Class<T> type) {
        return org.mockito.ArgumentMatchers.any(type);
    }
}

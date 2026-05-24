package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.warrenstrange.googleauth.GoogleAuthenticator;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerMfa;
import hu.puzzleir.valuta.repository.WorkerMfaRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * TOTP service teszt — Sprint 3 (P2-A).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TotpServiceTest {

    @Mock private WorkerMfaRepository mfaRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Spy private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private TotpService totpService;

    private static final Long WORKER_ID = 42L;
    private Worker worker;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(totpService, "mfaIssuer", "TestIssuer");
        worker = new Worker();
        worker.setId(WORKER_ID);
        worker.setCode("TESTUSER");
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
        when(mfaRepository.save(any(WorkerMfa.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("startEnrollment — secret + QR + otpAuthUrl generálódik")
    void startEnrollment_returnsSecretAndQr() {
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.empty());

        var response = totpService.startEnrollment(WORKER_ID);

        assertThat(response.getSecret()).isNotBlank();
        assertThat(response.getOtpAuthUrl()).startsWith("otpauth://totp/");
        assertThat(response.getOtpAuthUrl()).contains("TestIssuer");
        assertThat(response.getOtpAuthUrl()).contains("TESTUSER");
        assertThat(response.getQrCodePngBase64()).isNotBlank();
    }

    @Test
    @DisplayName("completeEnrollment — valid kóddal aktivál + backup codes generálódnak")
    void completeEnrollment_validCode_activates() {
        // Először startEnrollment hogy legyen secret
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.empty());
        var enrollResponse = totpService.startEnrollment(WORKER_ID);

        // Helyes kód generálása a secret-ből
        GoogleAuthenticator gAuth = new GoogleAuthenticator();
        int validCode = gAuth.getTotpPassword(enrollResponse.getSecret());

        // A startEnrollment által mentett MFA állapot
        WorkerMfa savedMfa = WorkerMfa.builder()
                .workerId(WORKER_ID)
                .type("TOTP")
                .secret(enrollResponse.getSecret())
                .isEnrolled(false)
                .isEnabled(false)
                .build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(savedMfa));

        var completeResponse = totpService.completeEnrollment(WORKER_ID, validCode);

        assertThat(completeResponse.getBackupCodes()).hasSize(8);
        assertThat(completeResponse.getBackupCodes()).allMatch(c -> c.length() == 8);
        assertThat(completeResponse.getMessage()).contains("MFA sikeresen aktiválva");
    }

    @Test
    @DisplayName("completeEnrollment — érvénytelen kód → ValidationException")
    void completeEnrollment_invalidCode_throws() {
        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID)
                .secret("ABCDEFGHIJKLMNOP") // fix secret a teszthez
                .isEnrolled(false)
                .build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));

        assertThatThrownBy(() -> totpService.completeEnrollment(WORKER_ID, 123456))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("Érvénytelen TOTP kód");
    }

    @Test
    @DisplayName("completeEnrollment — már enrolled állapot → ValidationException")
    void completeEnrollment_alreadyEnrolled_throws() {
        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID)
                .secret("ABCDEFGHIJKLMNOP")
                .isEnrolled(true)
                .build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));

        assertThatThrownBy(() -> totpService.completeEnrollment(WORKER_ID, 123456))
                .isInstanceOf(hu.puzzleir.valuta.exception.ValidationException.class)
                .hasMessageContaining("már enrolled");
    }

    @Test
    @DisplayName("verify — nincs MFA → false")
    void verify_noMfa_returnsFalse() {
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.empty());

        boolean result = totpService.verify(WORKER_ID, 123456);

        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("verify — disabled MFA → false")
    void verify_disabledMfa_returnsFalse() {
        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID)
                .secret("ABCDEFGHIJKLMNOP")
                .isEnabled(false)
                .build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));

        boolean result = totpService.verify(WORKER_ID, 123456);

        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("verify — replay protection (ugyanaz kód kétszer)")
    void verify_replayProtection() {
        GoogleAuthenticator gAuth = new GoogleAuthenticator();
        String secret = "JBSWY3DPEHPK3PXP"; // base32 teszt secret
        int validCode = gAuth.getTotpPassword(secret);

        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID)
                .secret(secret)
                .isEnabled(true)
                .lastUsedCode(String.valueOf(validCode))
                .build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));

        // Ugyanaz a kód, ami már szerepel lastUsedCode-ban → false (replay)
        boolean result = totpService.verify(WORKER_ID, validCode);
        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("isMfaRequired — enabled MFA → true")
    void isMfaRequired_enabled_returnsTrue() {
        when(mfaRepository.existsByWorkerIdAndIsEnabledTrue(WORKER_ID)).thenReturn(true);

        assertThat(totpService.isMfaRequired(WORKER_ID)).isTrue();
    }

    @Test
    @DisplayName("isMfaRequired — disabled MFA → false")
    void isMfaRequired_disabled_returnsFalse() {
        when(mfaRepository.existsByWorkerIdAndIsEnabledTrue(WORKER_ID)).thenReturn(false);

        assertThat(totpService.isMfaRequired(WORKER_ID)).isFalse();
    }

    @Test
    @DisplayName("disable — meglévő MFA-t letilt")
    void disable_existing_setsEnabledFalse() {
        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID)
                .secret("ABCDEFGHIJKLMNOP")
                .isEnabled(true)
                .build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));

        totpService.disable(WORKER_ID);

        assertThat(mfa.getIsEnabled()).isFalse();
        verify(mfaRepository).save(mfa);
    }

    // ==========================================================================
    // PP-16: BCrypt backup kód tesztek
    // ==========================================================================

    @Test
    @DisplayName("PP-16: backup kódok BCrypt formátumban tárolódnak, nem SHA-256 Base64")
    void PP16_backupCodes_storedAsBcryptFormat() {
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.empty());
        var enrollResponse = totpService.startEnrollment(WORKER_ID);
        GoogleAuthenticator gAuth = new GoogleAuthenticator();
        int validCode = gAuth.getTotpPassword(enrollResponse.getSecret());

        WorkerMfa savedMfa = WorkerMfa.builder()
                .workerId(WORKER_ID).type("TOTP").secret(enrollResponse.getSecret())
                .isEnrolled(false).isEnabled(false).build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(savedMfa));
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$12$fakebcrypthash123456");
        ArgumentCaptor<WorkerMfa> captor = ArgumentCaptor.forClass(WorkerMfa.class);

        totpService.completeEnrollment(WORKER_ID, validCode);

        verify(mfaRepository, atLeastOnce()).save(captor.capture());
        WorkerMfa captured = captor.getAllValues().stream()
                .filter(m -> m.getBackupCodesHashJson() != null)
                .findFirst().orElseThrow();
        assertThat(captured.getBackupCodesHashJson()).contains("$2a$12$");
        // SHA-256 Base64-kódolt hashek nem tartalmaznak '$' jelet
        assertThat(captured.getBackupCodesHashJson()).doesNotContain("SHA");
    }

    @Test
    @DisplayName("PP-16: verifyBackupCode — helyes kód → true, és az egy-szeri kód eltávolítódik")
    void PP16_verifyBackupCode_validCode_removesCodeAndReturnsTrue() throws Exception {
        String validCode = "12345678";
        String matchingHash = "$2a$12$matchinghash123456789a";
        String otherHash    = "$2a$12$otherhash0000000000000b";
        String json = new ObjectMapper().writeValueAsString(List.of(matchingHash, otherHash));

        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID).isEnabled(true).backupCodesHashJson(json).build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));
        when(passwordEncoder.matches(validCode, matchingHash)).thenReturn(true);
        ArgumentCaptor<WorkerMfa> captor = ArgumentCaptor.forClass(WorkerMfa.class);

        boolean result = totpService.verifyBackupCode(WORKER_ID, validCode);

        assertThat(result).isTrue();
        verify(mfaRepository).save(captor.capture());
        assertThat(captor.getValue().getBackupCodesHashJson()).contains(otherHash);
        assertThat(captor.getValue().getBackupCodesHashJson()).doesNotContain(matchingHash);
    }

    @Test
    @DisplayName("PP-16: verifyBackupCode — helytelen kód → false, nincs mentés")
    void PP16_verifyBackupCode_invalidCode_returnsFalse() throws Exception {
        String json = new ObjectMapper().writeValueAsString(
                List.of("$2a$12$hash1aaaaaaaaaaaaaaaaaa", "$2a$12$hash2aaaaaaaaaaaaaaaaaa"));
        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID).isEnabled(true).backupCodesHashJson(json).build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));
        when(passwordEncoder.matches(anyString(), anyString())).thenReturn(false);

        boolean result = totpService.verifyBackupCode(WORKER_ID, "99999999");

        assertThat(result).isFalse();
        verify(mfaRepository, never()).save(any());
    }

    @Test
    @DisplayName("PP-16: verifyBackupCode — nincs MFA rekord → false")
    void PP16_verifyBackupCode_noMfa_returnsFalse() {
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.empty());

        boolean result = totpService.verifyBackupCode(WORKER_ID, "12345678");

        assertThat(result).isFalse();
        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }

    @Test
    @DisplayName("PP-16: verifyBackupCode — MFA disabled → false")
    void PP16_verifyBackupCode_disabledMfa_returnsFalse() {
        WorkerMfa mfa = WorkerMfa.builder()
                .workerId(WORKER_ID).isEnabled(false).build();
        when(mfaRepository.findByWorkerId(WORKER_ID)).thenReturn(Optional.of(mfa));

        boolean result = totpService.verifyBackupCode(WORKER_ID, "12345678");

        assertThat(result).isFalse();
        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }
}

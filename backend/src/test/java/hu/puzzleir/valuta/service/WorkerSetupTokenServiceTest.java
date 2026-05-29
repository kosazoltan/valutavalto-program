package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.WorkerSetupToken;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerSetupTokenRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@link WorkerSetupTokenService} egysegtesztek (F-001 fix).
 *
 * <p>A publikus null-hash first-time-worker-setup fiokatvetel elleni setup-token
 * kiallitas + egyszer-hasznalatos, lejaro, scope-elt ellenorzes regresszio-vedelme.</p>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("WorkerSetupTokenService — F-001 setup-token kiallitas + ellenorzes")
class WorkerSetupTokenServiceTest {

    @Mock private WorkerSetupTokenRepository tokenRepository;

    @InjectMocks private WorkerSetupTokenService service;

    private static final Long WORKER_ID = 42L;
    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("issueToken — nem-ures raw tokent ad, es HASH-t (nem a raw-t) tarol, jovobeli lejarattal")
    void issueToken_storesHashNotRaw() {
        when(tokenRepository.save(any(WorkerSetupToken.class))).thenAnswer(inv -> inv.getArgument(0));

        String raw = service.issueToken(WORKER_ID, COMPANY_ID, 99L);

        assertThat(raw).isNotBlank();
        ArgumentCaptor<WorkerSetupToken> captor = ArgumentCaptor.forClass(WorkerSetupToken.class);
        verify(tokenRepository).save(captor.capture());
        WorkerSetupToken saved = captor.getValue();
        assertThat(saved.getTokenHash()).isNotBlank().isNotEqualTo(raw);
        assertThat(saved.getTokenHash()).hasSize(64); // SHA-256 hex
        assertThat(saved.getWorkerId()).isEqualTo(WORKER_ID);
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getCreatedBy()).isEqualTo(99L);
        assertThat(saved.getExpiresAt()).isAfter(Instant.now());
        assertThat(saved.getUsedAt()).isNull();
    }

    @Test
    @DisplayName("issueToken — worker/cég nélkül ValidationException")
    void issueToken_requiresWorkerAndCompany() {
        assertThatThrownBy(() -> service.issueToken(null, COMPANY_ID, 1L))
                .isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> service.issueToken(WORKER_ID, null, 1L))
                .isInstanceOf(ValidationException.class);
        verify(tokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("validateAndConsume — ures/null token ValidationException (a null-hash setup blokkolasa)")
    void validate_blankToken_rejected() {
        assertThatThrownBy(() -> service.validateAndConsume(null, WORKER_ID, COMPANY_ID))
                .isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> service.validateAndConsume("   ", WORKER_ID, COMPANY_ID))
                .isInstanceOf(ValidationException.class);
        verify(tokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("validateAndConsume — ismeretlen/felhasznalt hash ValidationException")
    void validate_unknownToken_rejected() {
        when(tokenRepository.findByTokenHashAndUsedAtIsNull(anyString())).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.validateAndConsume("akarmi", WORKER_ID, COMPANY_ID))
                .isInstanceOf(ValidationException.class);
        verify(tokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("validateAndConsume — lejart token ValidationException")
    void validate_expiredToken_rejected() {
        WorkerSetupToken expired = WorkerSetupToken.builder()
                .id(1L).tokenHash("h").workerId(WORKER_ID).companyId(COMPANY_ID)
                .issuedAt(Instant.now().minusSeconds(7200))
                .expiresAt(Instant.now().minusSeconds(3600)) // mar lejart
                .build();
        when(tokenRepository.findByTokenHashAndUsedAtIsNull(anyString())).thenReturn(Optional.of(expired));

        assertThatThrownBy(() -> service.validateAndConsume("raw", WORKER_ID, COMPANY_ID))
                .isInstanceOf(ValidationException.class);
        verify(tokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("validateAndConsume — más workerhez/céghez tartozó token ValidationException (scope)")
    void validate_wrongScope_rejected() {
        WorkerSetupToken other = WorkerSetupToken.builder()
                .id(2L).tokenHash("h").workerId(999L).companyId(COMPANY_ID)
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(tokenRepository.findByTokenHashAndUsedAtIsNull(anyString())).thenReturn(Optional.of(other));

        assertThatThrownBy(() -> service.validateAndConsume("raw", WORKER_ID, COMPANY_ID))
                .isInstanceOf(ValidationException.class);
        verify(tokenRepository, never()).save(any());
    }

    @Test
    @DisplayName("validateAndConsume — érvényes token: felhasználva (used_at beállítva)")
    void validate_validToken_consumed() {
        WorkerSetupToken valid = WorkerSetupToken.builder()
                .id(3L).tokenHash("h").workerId(WORKER_ID).companyId(COMPANY_ID)
                .issuedAt(Instant.now()).expiresAt(Instant.now().plusSeconds(3600))
                .build();
        when(tokenRepository.findByTokenHashAndUsedAtIsNull(anyString())).thenReturn(Optional.of(valid));
        when(tokenRepository.save(any(WorkerSetupToken.class))).thenAnswer(inv -> inv.getArgument(0));

        service.validateAndConsume("raw", WORKER_ID, COMPANY_ID);

        ArgumentCaptor<WorkerSetupToken> captor = ArgumentCaptor.forClass(WorkerSetupToken.class);
        verify(tokenRepository).save(captor.capture());
        assertThat(captor.getValue().getUsedAt()).isNotNull(); // egyszer hasznalatos
    }
}

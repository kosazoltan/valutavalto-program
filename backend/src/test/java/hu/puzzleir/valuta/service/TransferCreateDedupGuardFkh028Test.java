package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.IdempotencyRecord;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.repository.IdempotencyRecordRepository;
import org.hibernate.exception.ConstraintViolationException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.dao.DataIntegrityViolationException;

import java.sql.SQLException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-028 6. kör (Codex HIGH/MEDIUM): a TransferCreateDedupGuard célzott unit tesztjei —
 * pesszimista zár-alapú újrafoglalás, beragadt-PROCESSING kompenzáció, és szűkített
 * (constraint-név alapú) duplikátum-detekció. (A valódi, két-tranzakciós konkurencia-
 * bizonyítékot a külön TransferCreateDedupGuardConcurrencyPostgresTest adja, CI-ben.)
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransferCreateDedupGuardFkh028Test {

    @Mock private IdempotencyRecordRepository repository;

    private TransferCreateDedupGuard guard;

    private final UUID companyId = UUID.randomUUID();
    private static final String KEY = "abc123";

    @BeforeEach
    void setUp() {
        guard = new TransferCreateDedupGuard(repository);
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    private IdempotencyRecord record(IdempotencyRecord.Status status, Instant createdAt, Instant completedAt) {
        return IdempotencyRecord.builder()
                .id(1L)
                .companyId(companyId)
                .endpoint(TransferCreateDedupGuard.ENDPOINT)
                .idempotencyKey(KEY)
                .requestHash(KEY)
                .status(status)
                .createdAt(createdAt)
                .completedAt(completedAt)
                .expiresAt(Instant.now().plus(1, ChronoUnit.HOURS))
                .build();
    }

    @Test
    @DisplayName("HIGH (zár): a meglévő rekordot a FOR UPDATE lookup tölti be (nem a sima find) — a döntés a zár alatt születik")
    void existingRecord_isLoadedWithPessimisticLock() {
        when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(
                companyId, TransferCreateDedupGuard.ENDPOINT, KEY))
                .thenReturn(Optional.of(record(IdempotencyRecord.Status.FAILED, Instant.now(), Instant.now())));

        guard.acquire(companyId, KEY);

        verify(repository).findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(
                companyId, TransferCreateDedupGuard.ENDPOINT, KEY);
    }

    @Test
    @DisplayName("7. kör (Codex BLOCKING után): PROCESSING rekordra MINDIG 409 — az automatikus stale-átvétel kivezetve, a régi (20 perces) PROCESSING sem vehető át")
    void processingRecord_alwaysConflicts_regardlessOfAge() {
        // SPEC-VÁLTÁS (7. kör, dokumentált döntés): a 6. körben bevezetett 10 perces
        // automatikus stale-átvételre a Codex BLOCKING-ot adott (nincs garancia, hogy a
        // legitim kérés 10 percnél rövidebb, és a release nem tulajdonos-alapú — az
        // "ellopott" rekordot az eredeti kérés felülírhatná). A beragadt rekord feloldása
        // mostantól MANUÁLIS admin-eljárás (docs/ops/idempotency-stuck-record-recovery.md),
        // a monitorozást a TransferDedupStuckRecordWarningJob adja.

        // Friss PROCESSING → konfliktus (normál dupla-beküldés védelem).
        when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(
                companyId, TransferCreateDedupGuard.ENDPOINT, KEY))
                .thenReturn(Optional.of(record(IdempotencyRecord.Status.PROCESSING, Instant.now(), null)));
        assertThatThrownBy(() -> guard.acquire(companyId, KEY))
                .isInstanceOf(ConflictException.class);

        // RÉGI (20 perces) PROCESSING → TOVÁBBRA IS konfliktus, nincs automatikus átvétel.
        when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(
                companyId, TransferCreateDedupGuard.ENDPOINT, KEY))
                .thenReturn(Optional.of(record(IdempotencyRecord.Status.PROCESSING,
                        Instant.now().minus(20, ChronoUnit.MINUTES), null)));
        assertThatThrownBy(() -> guard.acquire(companyId, KEY))
                .as("A régi PROCESSING rekord sem vehető át automatikusan")
                .isInstanceOf(ConflictException.class);
    }

    @Test
    @DisplayName("MEDIUM (szűkebb detekció): a NEM a dedup-unique-indexre hivatkozó integritási hiba TOVÁBBTERJED, nem lesz belőle duplikátum-409")
    void unrelatedIntegrityViolation_isRethrown_notConvertedToConflict() {
        when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(any(), any(), any()))
                .thenReturn(Optional.empty());
        DataIntegrityViolationException other = new DataIntegrityViolationException("insert failed",
                new ConstraintViolationException("fk violation", new SQLException("fk", "23503"),
                        "valami_mas_fk_constraint"));
        when(repository.save(any())).thenThrow(other);

        assertThatThrownBy(() -> guard.acquire(companyId, KEY))
                .as("Más okú integritási hiba nem alakulhat duplikátum-409-cé")
                .isNotInstanceOf(ConflictException.class)
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    @DisplayName("Regresszió: a dedup-unique-indexre hivatkozó ütközés viszont duplikátum-409")
    void dedupUniqueViolation_isConflict() {
        when(repository.findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate(any(), any(), any()))
                .thenReturn(Optional.empty());
        DataIntegrityViolationException dup = new DataIntegrityViolationException("insert failed",
                new ConstraintViolationException("unique violation", new SQLException("dup", "23505"),
                        "idempotency_record_unique_idx"));
        when(repository.save(any())).thenThrow(dup);

        assertThatThrownBy(() -> guard.acquire(companyId, KEY))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("duplikált");
    }
}

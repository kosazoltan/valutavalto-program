package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.IdempotencyRecord;
import jakarta.persistence.LockModeType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Lock;

import java.lang.reflect.Method;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-028 8. kör: reflection-alapú regresszió-védelem a @Lock(PESSIMISTIC_WRITE)
 * annotáció elcsúszása ellen. Lokálisan fut (nincs Docker/DB igénye), és mindkét
 * irányt fedi:
 * <ul>
 *   <li>a TransferCreateDedupGuard által használt FOR UPDATE finderen KÖTELEZŐ a
 *       pesszimista write-lock (a FAILED/lejárt COMPLETED újrafoglalási race ellen),</li>
 *   <li>a csak-riasztó TransferDedupStuckRecordWarningJob finderén TILOS bármilyen
 *       lock-annotáció (a job "csak olvas" garanciája miatt).</li>
 * </ul>
 * A tényleges DB-szintű lock-viselkedést a CI-only
 * TransferCreateDedupGuardConcurrencyPostgresTest bizonyítja — ez a teszt csak az
 * annotáció helyes kihelyezését őrzi.
 */
class IdempotencyRecordRepositoryLockAnnotationFkh028Test {

    @Test
    @DisplayName("A ForUpdate finderen jelen van a @Lock(PESSIMISTIC_WRITE)")
    void forUpdateFinder_hasPessimisticWriteLock() throws NoSuchMethodException {
        Method method = IdempotencyRecordRepository.class.getMethod(
                "findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate",
                UUID.class, String.class, String.class);

        Lock lock = method.getAnnotation(Lock.class);
        assertThat(lock)
                .as("A findByCompanyIdAndEndpointAndIdempotencyKeyForUpdate metóduson "
                        + "kötelező a @Lock annotáció — nélküle a dedup-guard "
                        + "FAILED->PROCESSING újrafoglalása race-es")
                .isNotNull();
        assertThat(lock.value())
                .as("A lock módnak PESSIMISTIC_WRITE-nak kell lennie (SELECT ... FOR UPDATE)")
                .isEqualTo(LockModeType.PESSIMISTIC_WRITE);
    }

    @Test
    @DisplayName("A warning-job finderén NINCS @Lock annotáció (csak-riasztó, read-only)")
    void warningJobFinder_hasNoLockAnnotation() throws NoSuchMethodException {
        Method method = IdempotencyRecordRepository.class.getMethod(
                "findByEndpointAndStatusAndCreatedAtBefore",
                String.class, IdempotencyRecord.Status.class, Instant.class);

        assertThat(method.getAnnotation(Lock.class))
                .as("A findByEndpointAndStatusAndCreatedAtBefore a csak-riasztó "
                        + "TransferDedupStuckRecordWarningJob finderé — pesszimista lock "
                        + "beragadt rekordokra tilos, sima olvasásnak kell maradnia")
                .isNull();
    }
}

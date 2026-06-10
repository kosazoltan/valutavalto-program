package hu.puzzleir.valuta.repository;

import jakarta.persistence.LockModeType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

import java.lang.reflect.Method;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class WorkerRepositoryLockContractTest {

    @Test
    @DisplayName("findByIdForUpdate: PESSIMISTIC_WRITE lock szerzodes a penztarosi kvota TOCTOU ellen")
    void findByIdForUpdateHasPessimisticWriteLock() throws NoSuchMethodException {
        Method method = WorkerRepository.class.getMethod("findByIdForUpdate", Long.class);

        Lock lock = method.getAnnotation(Lock.class);
        Query query = method.getAnnotation(Query.class);

        assertThat(lock)
                .as("A napi penztarosi sajat-arfolyam kvota szerializalasahoz lockolt worker sort kell olvasni")
                .isNotNull();
        assertThat(lock.value()).isEqualTo(LockModeType.PESSIMISTIC_WRITE);
        assertThat(query)
                .as("A lockolt metódus explicit id-alapu Worker query legyen")
                .isNotNull();
        assertThat(query.value()).contains("SELECT w FROM Worker w WHERE w.id = :id");
        assertThat(method.getReturnType()).isEqualTo(Optional.class);
    }
}

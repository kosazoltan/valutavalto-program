package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SyncOutboxEvent;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SyncOutboxRepository extends JpaRepository<SyncOutboxEvent, UUID> {

    @Query("SELECT e FROM SyncOutboxEvent e " +
           "WHERE e.status = 'PENDING' " +
           "AND (e.nextRetryAt IS NULL OR e.nextRetryAt <= :now) " +
           "ORDER BY e.createdAt ASC")
    List<SyncOutboxEvent> findReadyForDispatch(@Param("now") LocalDateTime now, Pageable pageable);

    Optional<SyncOutboxEvent> findByIdempotencyKey(String idempotencyKey);
}

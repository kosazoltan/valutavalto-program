package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SyncInboxEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SyncInboxRepository extends JpaRepository<SyncInboxEvent, UUID> {

    Optional<SyncInboxEvent> findByIdempotencyKey(String idempotencyKey);
}

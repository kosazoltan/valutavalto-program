package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.NeonSyncLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface NeonSyncLogRepository extends JpaRepository<NeonSyncLog, UUID> {

    Optional<NeonSyncLog> findTopByStatusOrderBySyncStartedAtDesc(String status);

    Optional<NeonSyncLog> findTopByTableNameAndStatusOrderBySyncFinishedAtDesc(String tableName, String status);
}

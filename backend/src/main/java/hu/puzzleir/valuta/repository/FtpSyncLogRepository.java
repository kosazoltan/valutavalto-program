package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.FtpSyncLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface FtpSyncLogRepository extends JpaRepository<FtpSyncLog, UUID> {

    List<FtpSyncLog> findByBranchIdOrderByStartedAtDesc(UUID branchId);
}

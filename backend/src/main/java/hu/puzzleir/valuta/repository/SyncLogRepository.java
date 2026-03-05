package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SyncLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SyncLogRepository extends JpaRepository<SyncLog, UUID> {

    Page<SyncLog> findByBranchIdOrderByStartedAtDesc(UUID branchId, Pageable pageable);

    @Query("SELECT s FROM SyncLog s WHERE s.branch.id = :branchId " +
           "AND s.status = 'COMPLETED' ORDER BY s.completedAt DESC")
    List<SyncLog> findLastCompletedByBranch(@Param("branchId") UUID branchId);
}

package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BranchStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BranchStatusRepository extends JpaRepository<BranchStatus, UUID> {

    Optional<BranchStatus> findByBranchId(UUID branchId);

    List<BranchStatus> findByIsOnlineTrue();

    @Query("SELECT b FROM BranchStatus b WHERE b.lastHeartbeat IS NULL OR b.lastHeartbeat < :threshold")
    List<BranchStatus> findOfflineBranches(@Param("threshold") LocalDateTime threshold);

    /**
     * BranchStatus lekerese branch ID lista alapjan (multi-tenant szures).
     */
    List<BranchStatus> findByBranchIdIn(List<UUID> branchIds);
}

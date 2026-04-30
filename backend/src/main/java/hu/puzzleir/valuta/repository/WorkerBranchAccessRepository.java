package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerBranchAccess;
import hu.puzzleir.valuta.entity.WorkerBranchAccess.WorkerBranchAccessId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * v2.4.0 (B6 audit fix) — Repository for {@link WorkerBranchAccess}.
 *
 * Industry pattern: explicit {@code existsBy*} for hot-path access checks
 * (avoids fetching the full entity for boolean lookup).
 */
@Repository
public interface WorkerBranchAccessRepository
        extends JpaRepository<WorkerBranchAccess, WorkerBranchAccessId> {

    /**
     * Hot-path access check: does the worker have access to the given branch?
     * Used by every transaction-recording endpoint that resolves a non-default
     * branch (JWT branchOverride).
     *
     * <p>Returns {@code true} if a record exists in {@code worker_branch_access}
     * for the (workerId, branchId) tuple, {@code false} otherwise.
     */
    boolean existsByWorkerIdAndBranchId(Long workerId, UUID branchId);

    /**
     * List all branches a worker has access to.
     * Used by the admin UI to display the worker's branch-access matrix
     * and by the SetupWizard frontend to populate the branch dropdown.
     */
    @Query("SELECT wba FROM WorkerBranchAccess wba "
            + "WHERE wba.workerId = :workerId "
            + "ORDER BY wba.grantedAt ASC")
    List<WorkerBranchAccess> findAllByWorkerIdOrderByGrantedAtAsc(
            @Param("workerId") Long workerId);

    /**
     * List all workers that have access to a given branch.
     * Used by the admin UI to display the branch's worker-access matrix.
     */
    @Query("SELECT wba FROM WorkerBranchAccess wba "
            + "WHERE wba.branchId = :branchId "
            + "ORDER BY wba.grantedAt ASC")
    List<WorkerBranchAccess> findAllByBranchIdOrderByGrantedAtAsc(
            @Param("branchId") UUID branchId);
}

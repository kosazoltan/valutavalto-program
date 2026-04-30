package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.WorkerBranchAccess;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerBranchAccessRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * v2.4.0 (B6 audit fix) — Multi-branch worker access service.
 *
 * <p>Centralized API for the {@code worker_branch_access} M:N table:
 * <ul>
 *   <li>{@link #hasAccess(Long, UUID)}: hot-path boolean check (existsBy*)</li>
 *   <li>{@link #grantAccess(Long, UUID, Long)}: admin grants access (audit-logged)</li>
 *   <li>{@link #revokeAccess(Long, UUID)}: admin revokes access (audit-logged)</li>
 *   <li>{@link #listBranches(Long)}: admin UI worker → branches matrix</li>
 *   <li>{@link #listWorkers(UUID)}: admin UI branch → workers matrix</li>
 * </ul>
 *
 * <p>Industry pattern: defense-in-depth multi-tenant ACL.
 * <ul>
 *   <li><b>OWASP A01</b>: Broken Access Control — explicit grant required, default deny</li>
 *   <li><b>OWASP A09</b>: Logging — every grant/revoke audit-logged with [BRANCH_ACCESS] code</li>
 *   <li><b>Fail-loud</b>: revoke of non-existent access raises ValidationException, NEM silently no-op</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerBranchAccessService {

    private final WorkerBranchAccessRepository repo;

    /**
     * Hot-path access check.
     *
     * <p>Used by every {@code TransactionService} (and similar tx-recording
     * services) that resolves a non-default branch from JWT branchOverride.
     *
     * @param workerId the authenticated worker's id
     * @param branchId the branch the worker wants to operate on
     * @return {@code true} if access is granted, {@code false} otherwise
     */
    @Transactional(readOnly = true)
    public boolean hasAccess(Long workerId, UUID branchId) {
        if (workerId == null || branchId == null) return false;
        return repo.existsByWorkerIdAndBranchId(workerId, branchId);
    }

    /**
     * Validate that a worker has access to a branch, throws if not.
     * Convenience method for transaction-recording endpoints that want
     * fail-loud behavior (vs. silent fallback to worker.branchId).
     *
     * @throws ValidationException if access is denied
     */
    @Transactional(readOnly = true)
    public void requireAccess(Long workerId, UUID branchId) {
        if (!hasAccess(workerId, branchId)) {
            log.warn("[BRANCH_ACCESS] denied: workerId={} branchId={}",
                    workerId, branchId);
            throw new ValidationException(
                    "Worker " + workerId + " has no access to branch " + branchId);
        }
    }

    /**
     * Admin grants access to a worker for a branch.
     * Idempotent: re-granting an existing access is a no-op (NEM creates duplicate).
     *
     * @param workerId           the target worker
     * @param branchId           the target branch
     * @param grantedByWorkerId  the admin who issued the grant (null = system)
     */
    @Transactional
    public WorkerBranchAccess grantAccess(Long workerId, UUID branchId,
                                          Long grantedByWorkerId) {
        if (workerId == null || branchId == null) {
            throw new ValidationException("workerId and branchId are required");
        }
        WorkerBranchAccess existing = repo.findById(
                new WorkerBranchAccess.WorkerBranchAccessId(workerId, branchId))
                .orElse(null);
        if (existing != null) {
            log.debug("[BRANCH_ACCESS] grant idempotent: worker={} branch={} (already granted)",
                    workerId, branchId);
            return existing;
        }
        WorkerBranchAccess access = WorkerBranchAccess.builder()
                .workerId(workerId)
                .branchId(branchId)
                .grantedAt(LocalDateTime.now())
                .grantedByWorkerId(grantedByWorkerId)
                .build();
        WorkerBranchAccess saved = repo.save(access);
        log.info("[BRANCH_ACCESS] granted: worker={} branch={} grantedBy={}",
                workerId, branchId, grantedByWorkerId);
        return saved;
    }

    /**
     * Admin revokes access. Fail-loud: if the access does NOT exist,
     * raises ValidationException (vs. silent no-op).
     *
     * <p>Future enhancement: prevent revoking the worker's last branch
     * (would lock them out completely). For now: NEM enforced —
     * admin is responsible.
     */
    @Transactional
    public void revokeAccess(Long workerId, UUID branchId) {
        WorkerBranchAccess.WorkerBranchAccessId id =
                new WorkerBranchAccess.WorkerBranchAccessId(workerId, branchId);
        if (!repo.existsById(id)) {
            log.warn("[BRANCH_ACCESS] revoke failed: workerId={} branchId={} (not found)",
                    workerId, branchId);
            throw new ValidationException(
                    "No branch access record for worker " + workerId
                            + " on branch " + branchId);
        }
        repo.deleteById(id);
        log.info("[BRANCH_ACCESS] revoked: worker={} branch={}", workerId, branchId);
    }

    /**
     * Admin UI: list all branches a worker has access to.
     */
    @Transactional(readOnly = true)
    public List<WorkerBranchAccess> listBranches(Long workerId) {
        return repo.findAllByWorkerIdOrderByGrantedAtAsc(workerId);
    }

    /**
     * Admin UI: list all workers with access to a branch.
     */
    @Transactional(readOnly = true)
    public List<WorkerBranchAccess> listWorkers(UUID branchId) {
        return repo.findAllByBranchIdOrderByGrantedAtAsc(branchId);
    }
}

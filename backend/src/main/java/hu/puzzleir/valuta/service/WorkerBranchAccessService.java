package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerBranchAccess;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.WorkerBranchAccessRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
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
 *   <li><b>Tenant boundary</b> (Codex P1 PR #326): grantAccess() validates worker.company == branch.company,
 *       cross-tenant grant is rejected with SecurityException-equivalent ValidationException.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerBranchAccessService {

    private final WorkerBranchAccessRepository repo;
    private final WorkerRepository workerRepo;
    private final BranchRepository branchRepo;

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
     *
     * <p>Pre-conditions (Codex P1 #326 tenant boundary):
     * <ul>
     *   <li>Worker MUST exist</li>
     *   <li>Branch MUST exist</li>
     *   <li>Worker.company.id MUST equal Branch.company.id (no cross-tenant grant)</li>
     * </ul>
     *
     * <p>Idempotent: re-granting an existing access is a no-op (NEM creates duplicate).
     *
     * @param workerId           the target worker
     * @param branchId           the target branch
     * @param grantedByWorkerId  the admin who issued the grant (null = system)
     * @throws ValidationException if input invalid, worker/branch missing, or cross-tenant grant
     */
    @Transactional
    public WorkerBranchAccess grantAccess(Long workerId, UUID branchId,
                                          Long grantedByWorkerId) {
        if (workerId == null || branchId == null) {
            throw new ValidationException("workerId and branchId are required");
        }

        // Tenant boundary check (Codex P1 #326): worker és branch ugyanahhoz a
        // company-hoz kell tartozzon. Cross-tenant grant TILOS, mert
        // hasAccess() ellenőrizetlenül engedne cross-company tranzakciót.
        Worker worker = workerRepo.findById(workerId)
                .orElseThrow(() -> {
                    log.warn("[BRANCH_ACCESS] grant rejected: worker NEM exists: workerId={}",
                            workerId);
                    return new ValidationException("Worker not found: " + workerId);
                });
        Branch branch = branchRepo.findById(branchId)
                .orElseThrow(() -> {
                    log.warn("[BRANCH_ACCESS] grant rejected: branch NEM exists: branchId={}",
                            branchId);
                    return new ValidationException("Branch not found: " + branchId);
                });
        UUID workerCompanyId = worker.getCompany() != null ? worker.getCompany().getId() : null;
        UUID branchCompanyId = branch.getCompany() != null ? branch.getCompany().getId() : null;
        if (workerCompanyId == null || branchCompanyId == null
                || !Objects.equals(workerCompanyId, branchCompanyId)) {
            log.warn("[BRANCH_ACCESS] tenant boundary violation: workerId={} workerCompany={} "
                            + "branchId={} branchCompany={}",
                    workerId, workerCompanyId, branchId, branchCompanyId);
            throw new ValidationException(
                    "Cross-tenant grant denied: worker " + workerId
                            + " (company " + workerCompanyId + ") cannot access branch "
                            + branchId + " (company " + branchCompanyId + ")");
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
        log.info("[BRANCH_ACCESS] granted: worker={} branch={} grantedBy={} company={}",
                workerId, branchId, grantedByWorkerId, workerCompanyId);
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
     *
     * <p>Tenant-guard (defense-in-depth, a grantAccess Codex P1 #326 mintája):
     * csak a bejelentkezett cég saját workerére hívható. Nem létező vagy más
     * cégbeli worker → ResourceNotFoundException (existence-masking).
     */
    @Transactional(readOnly = true)
    public List<WorkerBranchAccess> listBranches(Long workerId) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Worker worker = workerRepo.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Munkatárs nem található: " + workerId));
        if (worker.getCompany() == null
                || !currentCompanyId.equals(worker.getCompany().getId())) {
            log.warn("[BRANCH_ACCESS] cross-tenant listBranches denied: workerId={} company={}",
                    workerId, currentCompanyId);
            throw new ResourceNotFoundException("Munkatárs nem található: " + workerId);
        }
        return repo.findAllByWorkerIdOrderByGrantedAtAsc(workerId);
    }

    /**
     * Admin UI: list all workers with access to a branch.
     *
     * <p>Tenant-guard: csak a bejelentkezett cég saját branch-ére hívható.
     * Nem létező vagy más cégbeli branch → ResourceNotFoundException
     * (existence-masking, WesternUnionService.verifyBranchOwnership precedens).
     */
    @Transactional(readOnly = true)
    public List<WorkerBranchAccess> listWorkers(UUID branchId) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepo.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Iroda nem található: " + branchId));
        if (branch.getCompany() == null
                || !currentCompanyId.equals(branch.getCompany().getId())) {
            log.warn("[BRANCH_ACCESS] cross-tenant listWorkers denied: branchId={} company={}",
                    branchId, currentCompanyId);
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
        return repo.findAllByBranchIdOrderByGrantedAtAsc(branchId);
    }
}

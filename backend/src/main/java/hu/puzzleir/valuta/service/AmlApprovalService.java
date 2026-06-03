package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.TransactionAmlApproval;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionAmlApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

/**
 * AML felsővezetői jóváhagyás rögzítő szolgáltatás (Pmt. 14/A. § (4), 14/2025. MNB rendelet V.2.6).
 *
 * <p>A magas kockázatú esetekben (FATF 1/a, magas-kockázatú harmadik ország ≥5M Ft, PEP, éves limit)
 * a tranzakció kizárólag a kijelölt felelős vezető (supervisor/manager/admin) jóváhagyásával
 * teljesíthető. Ez a szolgáltatás validálja az engedélyező jogosultságát és INSERT-only audit-rekordba
 * rögzíti az engedélyező NEVÉT (a szabályzat V.2.6 4. lépése + 8 éves megőrzés).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AmlApprovalService {

    private final WorkerRepository workerRepository;
    private final TransactionAmlApprovalRepository approvalRepository;

    /** A jóváhagyásra jogosult worker-szerepek (Pmt. 14/A. § (4): kijelölt felelős vezető). */
    private static final Set<WorkerRole> SENIOR_APPROVER_ROLES =
            EnumSet.of(WorkerRole.SUPERVISOR, WorkerRole.MANAGER, WorkerRole.ADMIN);

    /**
     * Felsővezetői AML-jóváhagyás rögzítése. Validálja, hogy az {@code approverWorkerId} érvényes,
     * az aktuális céghez tartozó, supervisor-vagy-feljebb dolgozó; majd INSERT-only audit-rekordba
     * rögzíti az engedélyező NEVÉT. Érvénytelen/hiányzó engedélyezőnél {@link ValidationException}.
     *
     * @return a rögzített jóváhagyás (az engedélyező nevével).
     */
    @Transactional
    public TransactionAmlApproval recordSeniorApproval(Long approverWorkerId, String approvalReason,
            BigDecimal hufAmount, String customerName, String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        Worker approver = resolveSeniorApprover(approverWorkerId, companyId);

        TransactionAmlApproval rec = TransactionAmlApproval.builder()
                .companyId(companyId)
                .branchId(branchId)
                .receiptNumber(receiptNumber)
                .hufAmount(hufAmount)
                .customerName(customerName)
                .approvalReason(approvalReason != null ? approvalReason : "AML felsővezetői jóváhagyás")
                .approvedByWorkerId(approverWorkerId)
                .approvedByName(safeName(approver))
                .approvedAt(LocalDateTime.now())
                .build();
        TransactionAmlApproval saved = approvalRepository.save(rec);
        log.info("[AML-APPROVAL] Felsővezetői jóváhagyás rögzítve — engedélyező: {} (#{}), indok: {}",
                saved.getApprovedByName(), approverWorkerId, approvalReason);
        return saved;
    }

    /** True, ha az adott worker (az aktuális cégben) jogosult AML felsővezetői jóváhagyásra. */
    public boolean isValidSeniorApprover(Long workerId) {
        if (workerId == null) {
            return false;
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findById(workerId)
                .filter(w -> w.getCompany() != null && companyId.equals(w.getCompany().getId()))
                .map(w -> w.getRole() != null && SENIOR_APPROVER_ROLES.contains(w.getRole()))
                .orElse(false);
    }

    private Worker resolveSeniorApprover(Long approverWorkerId, UUID companyId) {
        if (approverWorkerId == null) {
            throw new ValidationException("AML felsővezetői jóváhagyás szükséges, de nincs megadva az engedélyező.");
        }
        Worker approver = workerRepository.findById(approverWorkerId)
                .orElseThrow(() -> new ValidationException(
                        "Az AML-engedélyező nem található (workerId=" + approverWorkerId + ")."));
        // Multi-tenant: az engedélyező az aktuális céghez tartozzon.
        if (approver.getCompany() == null || !companyId.equals(approver.getCompany().getId())) {
            throw new ValidationException("Az AML-engedélyező nem ehhez a céghez tartozik.");
        }
        if (approver.getRole() == null || !SENIOR_APPROVER_ROLES.contains(approver.getRole())) {
            throw new ValidationException("Az engedélyező (" + safeName(approver)
                    + ") nem jogosult AML felsővezetői jóváhagyásra (supervisor/manager/admin szükséges).");
        }
        return approver;
    }

    private static String safeName(Worker w) {
        return w.getName() != null && !w.getName().isBlank() ? w.getName() : ("#" + w.getId());
    }
}

package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AmlApprovalGrant;
import hu.puzzleir.valuta.entity.TransactionAmlApproval;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.AmlApprovalGrantRepository;
import hu.puzzleir.valuta.repository.TransactionAmlApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
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
    private final AmlApprovalGrantRepository grantRepository;

    /** A jóváhagyásra jogosult worker-szerepek (Pmt. 14/A. § (4): kijelölt felelős vezető). */
    private static final Set<WorkerRole> SENIOR_APPROVER_ROLES =
            EnumSet.of(WorkerRole.SUPERVISOR, WorkerRole.MANAGER, WorkerRole.ADMIN);

    /** Az engedély (grant) érvényessége — bőven fedi a local-first offline → sync késleltetést. */
    private static final int GRANT_VALIDITY_DAYS = 7;

    /**
     * Felsővezetői AML-jóváhagyás rögzítése. Validálja, hogy az {@code approverWorkerId} érvényes,
     * az aktuális céghez tartozó, supervisor-vagy-feljebb dolgozó, ÉS nem a tranzakciót rögzítő
     * pénztáros (4-szem-elv); majd INSERT-only audit-rekordba rögzíti az engedélyező NEVÉT.
     * Érvénytelen/hiányzó engedélyezőnél {@link ValidationException}.
     *
     * <p><b>Tranzakcionalitás:</b> a rögzítés a hívó tranzakció-flow tranzakcióján belül fut
     * ({@code REQUIRED}), így ha a tranzakció később rollbackel, a jóváhagyás-rekord is visszagördül —
     * azaz audit-rekord csak ténylegesen létrejött (committed) magas-kockázatú tranzakcióhoz tartozik,
     * nincs orphan jóváhagyás technikailag elhasalt kísérletekhez.</p>
     *
     * @return a rögzített jóváhagyás (az engedélyező nevével).
     */
    @Transactional
    public TransactionAmlApproval recordSeniorApproval(Long approverWorkerId, String approvalReason,
            BigDecimal hufAmount, String customerName, String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        Worker approver = resolveSeniorApprover(approverWorkerId, companyId);
        // PIN-jelenlét bizonyítása (Codex P1): csak akkor rögzítünk jóváhagyást, ha a /verify-approver
        // a supervisor-PIN sikeres ellenőrzésekor létrehozott egy egyszer-használatos grantot erre a
        // (cég, pénztáros, engedélyező) hármasra. Enélkül a bare approverWorkerId-vel forgeolható lenne
        // a jóváhagyás-audit. A grant rögzítéskor elhasználódik (a tranzakcióval együtt rollbackelhet).
        consumeApprovalGrant(approverWorkerId, companyId);

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
        // Az engedélyező NEVE az audit-rekordba kerül (V.2.6 kötelező); a sima app-logba viszont csak
        // a workerId — a teljes név PII, ne szivárogjon a Loki/Grafana log-streambe. Az indokot a MENTETT
        // rekordból logoljuk, hogy a log és az audit-rekord konzisztens legyen (a default-feloldás után).
        log.info("[AML-APPROVAL] Felsővezetői jóváhagyás rögzítve — engedélyező #{}, indok: {}",
                approverWorkerId, saved.getApprovalReason());
        return saved;
    }

    /**
     * Engedély (grant) kiállítása a supervisor-PIN SIKERES ellenőrzése után (a verify-approver hívja).
     * A grant bizonyítja, hogy az {@code approverWorkerId} PIN-nel igazolta a jelenlétét a bejelentkezett
     * (rögzítő) pénztáros sessionjében; a tranzakció-rögzítéskor ez fogy el (single-use).
     */
    @Transactional
    public void issueApprovalGrant(Long approverWorkerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long cashierWorkerId = SecurityUtils.getCurrentWorkerId();
        LocalDateTime now = LocalDateTime.now();
        AmlApprovalGrant grant = AmlApprovalGrant.builder()
                .companyId(companyId)
                .cashierWorkerId(cashierWorkerId)
                .approverWorkerId(approverWorkerId)
                .createdAt(now)
                .expiresAt(now.plusDays(GRANT_VALIDITY_DAYS))
                .build();
        grantRepository.save(grant);
        log.info("[AML-APPROVAL] Grant kiállítva — engedélyező #{}, pénztáros #{}", approverWorkerId, cashierWorkerId);
    }

    /**
     * Egyetlen fel nem használt, le nem járt grant elhasználása a (cég, pénztáros, engedélyező) hármasra.
     * Ha nincs ilyen → {@link ValidationException} (a jóváhagyás PIN-ellenőrzés nélkül nem rögzíthető).
     */
    private void consumeApprovalGrant(Long approverWorkerId, UUID companyId) {
        Long cashierWorkerId = SecurityUtils.getCurrentWorkerId();
        List<AmlApprovalGrant> grants = grantRepository.findConsumable(
                companyId, cashierWorkerId, approverWorkerId, LocalDateTime.now(), Limit.of(1));
        if (grants.isEmpty()) {
            throw new ValidationException("AML jóváhagyás PIN-ellenőrzés nélkül nem rögzíthető "
                    + "(hiányzó vagy lejárt engedély). Kérjen jóváhagyást az engedélyező supervisor-PIN-jével.");
        }
        AmlApprovalGrant grant = grants.get(0);
        grant.setUsedAt(LocalDateTime.now());
        grantRepository.save(grant);
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
        // 4-szem-elv (Pmt. 14/A. § (4)): az engedélyező NEM lehet a tranzakciót rögzítő pénztáros — nincs
        // implicit self-approval kiskapu. (A POS-on bejelentkezett dolgozó workerId-ját hasonlítjuk össze.)
        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        if (currentWorkerId != null && currentWorkerId.equals(approverWorkerId)) {
            throw new ValidationException(
                    "Az AML-engedélyező nem lehet a tranzakciót rögzítő dolgozó (4-szem-elv).");
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

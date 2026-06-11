package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.vaultchecklist.CompleteChecklistRequest;
import hu.puzzleir.valuta.dto.vaultchecklist.UpdateChecklistItemsRequest;
import hu.puzzleir.valuta.dto.vaultchecklist.VaultClosingChecklistDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.VaultClosingChecklist;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.VaultClosingChecklistRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Értéktári zárás-előtti ellenőrzőlista service.
 *
 * <p>FR-ZARUI-16..26 (b2-zaras-kepernyok-bizonylatok.md)</p>
 *
 * <p>Tenant guard minta: BankOrderService alapján — a company_id MINDIG
 * SecurityUtils.getCurrentCompanyId()-ból jön, NEM kliens inputból.
 * Cross-tenant kísérlet 404-et kap (információ-szivárgás megelőzés).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VaultClosingChecklistService {

    private final VaultClosingChecklistRepository checklistRepository;
    private final BranchRepository branchRepository;
    private final AuditLogService auditLogService;

    /**
     * Adott pénztár + dátum checklist lekérése, ha nem létezik létrehozza (idempotens).
     *
     * <p>company_id automatikusan a bejelentkezett felhasználó cégéből kerül be.
     * Cross-tenant kísérlet (más cég branch-e) 404-et kap.</p>
     *
     * @param branchId    pénztár UUID
     * @param closingDate zárás dátuma
     * @return DTO (soha nem null)
     */
    @Transactional
    public VaultClosingChecklistDto getOrCreate(UUID branchId, LocalDate closingDate) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = loadBranchWithTenantGuard(branchId, companyId);

        VaultClosingChecklist checklist = checklistRepository
                .findByCompanyIdAndBranch_IdAndClosingDate(companyId, branchId, closingDate)
                .orElseGet(() -> {
                    VaultClosingChecklist newChecklist = VaultClosingChecklist.builder()
                            .companyId(companyId)
                            .branch(branch)
                            .closingDate(closingDate)
                            .build();
                    VaultClosingChecklist saved = checklistRepository.save(newChecklist);
                    log.info("[vault-checklist] CREATE id={} branch={} date={}",
                            saved.getId(), branchId, closingDate);
                    return saved;
                });

        return VaultClosingChecklistDto.from(checklist);
    }

    /**
     * A 9 checklist-tétel frissítése (FR-ZARUI-17..25).
     *
     * @param branchId    pénztár UUID
     * @param closingDate zárás dátuma
     * @param req         az item_1..item_9 flag értékek
     * @return frissített DTO
     */
    @Transactional
    public VaultClosingChecklistDto updateItems(UUID branchId, LocalDate closingDate,
                                                UpdateChecklistItemsRequest req) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        loadBranchWithTenantGuard(branchId, companyId); // tenant guard

        VaultClosingChecklist checklist = requireChecklist(companyId, branchId, closingDate);

        checklist.setItem1(req.isItem1());
        checklist.setItem2(req.isItem2());
        checklist.setItem3(req.isItem3());
        checklist.setItem4(req.isItem4());
        checklist.setItem5(req.isItem5());
        checklist.setItem6(req.isItem6());
        checklist.setItem7(req.isItem7());
        checklist.setItem8(req.isItem8());
        checklist.setItem9(req.isItem9());

        VaultClosingChecklist saved = checklistRepository.save(checklist);
        log.debug("[vault-checklist] UPDATE_ITEMS id={} branch={} date={}", saved.getId(), branchId, closingDate);
        return VaultClosingChecklistDto.from(saved);
    }

    /**
     * Zárás véglegesítése — FR-ZARUI-26 ellenőrző személy adatai kötelezők.
     *
     * <p>auditorName és auditorRole üres esetén {@link ValidationException} dobódik.
     * Sikeres hívás audit log bejegyzést készít.</p>
     *
     * @param branchId    pénztár UUID
     * @param closingDate zárás dátuma
     * @param req         ellenőrző személy neve + beosztása
     * @return frissített DTO (completedAt kitöltve)
     */
    @Transactional
    public VaultClosingChecklistDto complete(UUID branchId, LocalDate closingDate,
                                             CompleteChecklistRequest req) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        loadBranchWithTenantGuard(branchId, companyId); // tenant guard

        // FR-ZARUI-26 validáció: üres auditor_name / auditor_role nem engedélyezett
        if (req.getAuditorName() == null || req.getAuditorName().isBlank()) {
            throw new ValidationException("Az ellenőrző személy neve kötelező (FR-ZARUI-26)");
        }
        if (req.getAuditorRole() == null || req.getAuditorRole().isBlank()) {
            throw new ValidationException("Az ellenőrző személy beosztása kötelező (FR-ZARUI-26)");
        }

        VaultClosingChecklist checklist = requireChecklist(companyId, branchId, closingDate);

        Long workerId = SecurityUtils.getCurrentWorkerId();
        checklist.setAuditorName(req.getAuditorName().trim());
        checklist.setAuditorRole(req.getAuditorRole().trim());
        checklist.setCompletedByWorkerId(workerId);
        checklist.setCompletedAt(LocalDateTime.now());

        VaultClosingChecklist saved = checklistRepository.save(checklist);

        // Audit log
        auditLogService.log(
                "VAULT_CLOSING_CHECKLIST_COMPLETE",
                String.format("Értéktári zárás-checklist véglegesítve: branch=%s date=%s auditor='%s' (%s)",
                        branchId, closingDate,
                        req.getAuditorName().trim(),
                        req.getAuditorRole().trim()),
                saved.getId().toString()
        );

        log.info("[vault-checklist] COMPLETE id={} branch={} date={} auditor='{}' worker={}",
                saved.getId(), branchId, closingDate,
                req.getAuditorName().trim(), workerId);

        return VaultClosingChecklistDto.from(saved);
    }

    // ===== privát segédmetódusok =====

    /**
     * Branch betöltése tenant guarddal — cross-tenant kísérlet 404 (BankOrderService minta).
     */
    private Branch loadBranchWithTenantGuard(UUID branchId, UUID companyId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztár nem található: " + branchId));
        if (companyId == null
                || branch.getCompany() == null
                || !companyId.equals(branch.getCompany().getId())) {
            // 404 — nem szivárogtatjuk, hogy létezik-e a branch másik cégnél
            throw new ResourceNotFoundException("Pénztár nem található: " + branchId);
        }
        return branch;
    }

    /**
     * Meglévő checklist keresése — ha nem létezik, 404 (updateItems / complete esetén
     * elvárjuk, hogy getOrCreate már lefutott).
     */
    private VaultClosingChecklist requireChecklist(UUID companyId, UUID branchId, LocalDate closingDate) {
        return checklistRepository
                .findByCompanyIdAndBranch_IdAndClosingDate(companyId, branchId, closingDate)
                .orElseThrow(() -> new ResourceNotFoundException(
                        String.format("Zárás-checklist nem található: branch=%s date=%s", branchId, closingDate)));
    }
}

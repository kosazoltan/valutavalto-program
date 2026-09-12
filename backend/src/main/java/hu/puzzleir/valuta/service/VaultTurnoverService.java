package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

/**
 * FKH-066: vault-facing, territory-scoped read of a cash desk's ACTUAL daily turnover.
 *
 * <p>The "Pénztári készletek" view used to show bank withdraw/deposit movements under the label
 * "Forgalom", which a cashier never performs - they deal with the customer and the vault only.
 * The correct figures (customer-facing BUY/SELL and the handling fee collected from the customer)
 * already exist in {@link TurnoverService}; what was missing is access for the ERTEKTAR role.</p>
 *
 * <p>Opening that data without a scope check would let a vault manager read another territory's
 * cash desk turnover, so the territory guard is part of the same change - deliberately mirroring
 * {@code InventoryMovementService.requireOwnBranch}: a branch outside the caller's scope behaves
 * as if it did not exist (404), never 403, so the response cannot confirm its existence.</p>
 *
 * <p>No new aggregation lives here: the report is produced by the existing
 * {@link TurnoverService#getDailyTurnover(UUID, LocalDate)}, so this view can never drift from
 * the numbers the head-vault endpoints report for the same branch and day.</p>
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class VaultTurnoverService {

    private final BranchRepository branchRepository;
    private final AccessScopeService accessScopeService;
    private final TurnoverService turnoverService;

    @Transactional(readOnly = true)
    public TurnoverReportDto getVaultDailyTurnover(UUID branchId, LocalDate date) {
        requireOwnBranch(branchId);
        return turnoverService.getDailyTurnover(branchId, date);
    }

    /**
     * Tenant + territory guard. Both failures raise the SAME not-found error on purpose: a
     * distinguishable response would reveal whether a branch id exists in another company or
     * another territory.
     */
    private void requireOwnBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchId == null || !branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        if (!accessScopeService.isBranchVisible(scope, branchId.toString())) {
            log.warn("FKH-066: branch outside the caller's vault territory scope, returning not-found. branchId={}",
                    branchId);
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
    }
}

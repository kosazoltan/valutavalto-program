package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.UUID;

/**
 * FKH-021: a havi zárás branch-szintű hozzáférésének egységes őre.
 *
 * <p>Az értéktári szerepkörök a saját session-branchükre korlátozottak; az ügyvezető
 * és a meglévő vezetői szerepkörök cég-szinten férnek hozzá.</p>
 */
@Service
@RequiredArgsConstructor
public class MonthlyClosingAccessGuard {

    private final BranchRepository branchRepository;

    public Branch requireAccessibleBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findByIdAndCompanyId(branchId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (!isOwnVaultOnlyRole()) {
            return branch;
        }

        UUID currentBranchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (currentBranchId == null || !currentBranchId.equals(branchId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }

        return branch;
    }

    private boolean isOwnVaultOnlyRole() {
        String activeRole = SecurityUtils.getActiveOperationalRole();
        String currentRole = activeRole != null ? activeRole : SecurityUtils.getCurrentRole();
        if (currentRole == null || currentRole.isBlank()) {
            return false;
        }
        return switch (currentRole.trim().toLowerCase(Locale.ROOT)) {
            case "ertektar", "vault_keeper", "foertektar", "chief_vault" -> true;
            default -> false;
        };
    }
}

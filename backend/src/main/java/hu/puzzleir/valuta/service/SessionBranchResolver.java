package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * A munkamenethez tartozó branch feloldása az aktív operatív szerepkör alapján.
 *
 * <p>FKH-019: az értéktári szerepkörök NEM a worker alapértelmezett branch-ét, hanem
 * a saját régiójuk aktív értéktárát kapják session-branchként.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SessionBranchResolver {

    private final BranchRepository branchRepository;

    public Branch resolveSessionBranch(Worker worker, String activeRole) {
        if (worker == null || worker.getCompany() == null || worker.getCompany().getId() == null) {
            throw new ValidationException("A munkamenet telephelye nem oldható fel: hiányzó dolgozó/cég.");
        }

        if (isVaultSessionRole(activeRole)) {
            return resolveVaultSessionBranch(worker);
        }

        Branch defaultBranch = worker.getBranch();
        if (defaultBranch != null) {
            return defaultBranch;
        }

        return fallbackCompanyBranch(worker.getCompany().getId());
    }

    private Branch resolveVaultSessionBranch(Worker worker) {
        UUID companyId = worker.getCompany().getId();
        String region = normalizeRegion(worker.getRegion());
        if (region == null && worker.getBranch() != null) {
            region = normalizeRegion(worker.getBranch().getRegion());
        }
        if (region == null) {
            log.warn("SESSION_BRANCH_RESOLVE_FAILED workerId={} activeRole=vault missingRegion", worker.getId());
            throw new ValidationException(
                    "Az értéktári munkamenet telephelye nem oldható fel: a dolgozó régiója hiányzik.");
        }

        List<Branch> vaultBranches = branchRepository.findActiveByCompanyIdAndRegion(companyId, region).stream()
                .filter(branch -> Boolean.TRUE.equals(branch.getIsVault()))
                .toList();
        if (vaultBranches.size() != 1) {
            log.error(
                    "SESSION_BRANCH_RESOLVE_FAILED workerId={} companyId={} region={} vaultCount={}",
                    worker.getId(), companyId, region, vaultBranches.size());
            throw new ValidationException(
                    "Az értéktári munkamenet telephelye nem oldható fel: a régióhoz nem pontosan egy aktív értéktár tartozik.");
        }

        return vaultBranches.get(0);
    }

    private Branch fallbackCompanyBranch(UUID companyId) {
        return branchRepository.findByCompanyIdAndIsActiveTrue(companyId).stream()
                .findFirst()
                .orElseGet(() -> branchRepository.findByCompanyId(companyId).stream()
                        .findFirst()
                        .orElseThrow(() -> new ValidationException("Nincs elérhető iroda a bejelentkezéshez!")));
    }

    static boolean isVaultSessionRole(String roleCode) {
        if (roleCode == null || roleCode.isBlank()) {
            return false;
        }
        String normalized = roleCode.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "ertektar", "ertektaros", "vault_keeper", "foertektar", "chief_vault" -> true;
            default -> false;
        };
    }

    private String normalizeRegion(String region) {
        if (region == null) {
            return null;
        }
        String normalized = region.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}

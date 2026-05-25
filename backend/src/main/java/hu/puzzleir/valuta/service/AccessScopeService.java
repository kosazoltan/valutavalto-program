package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * FK-005/A3 — terület (region_code) alapú adat-scope az értéktárosoknak.
 *
 * <p>Az értéktáros (ERTEKTAR / FOERTEKTAR) KIZÁRÓLAG a saját {@code region_code}-jához
 * tartozó pénztárakat láthatja az összesített nézetekben (Dashboard összesített készlet,
 * TOP-irodák, Pénztári készletek). A cég-szintű szerepkörök (MANAGER / ADMIN / UGYVEZETO)
 * a teljes céget látják — rájuk NINCS terület-szűkítés (nulla regresszió).
 *
 * <p>Kósa Zoltán user-direktíva (2026-05-25, „Értéktári jogosultság, átadás-átvételek"):
 * „Amikor értéktárosként bent vagyok, kizárólag a saját területemhez tartozó pénztárakat
 * szabad látnom a listákban és a menükben."
 */
@Service
@RequiredArgsConstructor
public class AccessScopeService {

    /** Cég-szintű (terület-független) szerepkörök — rájuk nincs scope-szűkítés. */
    private static final Set<String> COMPANY_WIDE_AUTHORITIES =
            Set.of("ROLE_MANAGER", "ROLE_ADMIN", "ROLE_UGYVEZETO");

    /** Értéktári (terület-kötött) szerepkörök — a saját region_code-ra szűkítve. */
    private static final Set<String> VAULT_AUTHORITIES =
            Set.of("ROLE_FOERTEKTAR", "ROLE_ERTEKTAR");

    private final BranchRepository branchRepository;

    /**
     * Visszaadja az aktuális felhasználó által látható branch-ID halmazt, VAGY {@code null}-t,
     * ha nincs terület-szűkítés (cég-szintű szerepkör vagy nem értéktári kontextus).
     *
     * @return {@code null} = nincs szűkítés (cég-szintű); egyébként az engedélyezett branch-ID-k
     *         (az értéktáros saját region_code-jához tartozó aktív pénztárak + a saját fiókja).
     *         Üres halmaz = nincs hozzáférhető pénztár (defenzív: nincs region és nincs branch).
     */
    @Transactional(readOnly = true)
    public Set<UUID> vaultRegionBranchScopeOrNull() {
        Set<String> authorities = currentAuthorities();

        // Cég-szintű role → teljes cég, nincs terület-szűkítés.
        if (authorities.stream().anyMatch(COMPANY_WIDE_AUTHORITIES::contains)) {
            return null;
        }
        // Nem értéktári role → ezt a @PreAuthorize governálja; itt nincs extra scope.
        if (authorities.stream().noneMatch(VAULT_AUTHORITIES::contains)) {
            return null;
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        String region = (branchId == null)
                ? null
                : branchRepository.findById(branchId).map(Branch::getRegionCode).orElse(null);

        // Nincs region_code → biztonságos default: csak a saját (értéktár) fiók.
        if (region == null || region.isBlank()) {
            return branchId == null ? Set.of() : Set.of(branchId);
        }

        Set<UUID> ids = branchRepository.findActiveByCompanyIdAndRegionCode(companyId, region)
                .stream()
                .map(Branch::getId)
                .collect(Collectors.toCollection(HashSet::new));
        if (branchId != null) {
            ids.add(branchId); // a saját értéktár fiók mindig látható
        }
        return ids;
    }

    /**
     * Igaz, ha a megadott branch-ID látható az aktuális felhasználónak (a terület-scope szerint).
     * {@code null} scope (cég-szintű) esetén MINDIG igaz.
     *
     * @param branchId a vizsgált pénztár ID-je String formában (CashBalanceDto.branchId)
     */
    public boolean isBranchVisible(Set<UUID> scopeOrNull, String branchId) {
        if (scopeOrNull == null) {
            return true;
        }
        if (branchId == null || branchId.isBlank()) {
            return false;
        }
        try {
            return scopeOrNull.contains(UUID.fromString(branchId));
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private Set<String> currentAuthorities() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getAuthorities() == null) {
            return Set.of();
        }
        return auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toSet());
    }
}

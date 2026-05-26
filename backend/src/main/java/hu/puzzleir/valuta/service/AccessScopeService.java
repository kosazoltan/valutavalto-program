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
 * FK-005/A3 — terület (region_code) alapú adat-scope a (régiós) értéktárosoknak.
 *
 * <p>A régiós értéktáros (ERTEKTAR) KIZÁRÓLAG a saját {@code region_code}-jához tartozó
 * pénztárakat láthatja az összesített nézetekben (Dashboard összesített készlet, TOP-irodák,
 * Pénztári/Országos készlet). A cég/országos-szintű szerepkörök (MANAGER / ADMIN / UGYVEZETO /
 * FŐÉRTÉKTÁR) a TELJES céget látják — rájuk NINCS terület-szűkítés.
 *
 * <p>HIBA 2026-05-26 (FK-005 regresszió, Kasza Helga – Főértéktár): a {@code FOERTEKTAR} a
 * NEMZETI/országos értéktár-vezető szerepkör (a menük „Országos készlet" / „Országos dashboard"),
 * ezért NEM régió-kötött. Korábban (Codex P1 #843) tévesen a régiós ERTEKTAR-ral azonos
 * scope-ot kapott → ha a belépési fiókjának nincs {@code region_code}-ja, a scope a saját
 * (üres) fiókjára szűkült → „Nincs adat". A főértéktárosnak az egész országot látnia kell.
 *
 * <p>Kósa Zoltán user-direktíva (2026-05-25, „Értéktári jogosultság, átadás-átvételek"):
 * „Amikor (régiós) értéktárosként bent vagyok, kizárólag a saját területemhez tartozó
 * pénztárakat szabad látnom a listákban és a menükben."
 */
@Service
@RequiredArgsConstructor
public class AccessScopeService {

    /** Terület-kötött (régiós) értéktári szerepkör — a saját region_code-ra szűkítve.
     *  Ha a felhasználó (aktívan) régiós értéktárosként operál, a terület-scope érvényes —
     *  akkor is, ha a base-role cég-szintű (MANAGER/ADMIN/UGYVEZETO). Lásd Codex P1 #843.
     *  HIBA 2026-05-26: a FŐÉRTÉKTÁR (ROLE_FOERTEKTAR) NEMZETI szerepkör → NEM tartozik ide,
     *  az egész országot látja (mint a cég-szintű role-ok). */
    private static final Set<String> VAULT_AUTHORITIES =
            Set.of("ROLE_ERTEKTAR");

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

        // Codex P1 (#843): a JwtAuthenticationFilter MINDKÉT authority-t hozzáadja
        // (ROLE_<base-role> + ROLE_<aktív operatív role>). Ezért a vault-szerepkört
        // ELSŐKÉNT vizsgáljuk: ha a felhasználó RÉGIÓS értéktárosként (ERTEKTAR) operál,
        // a terület-scope AKKOR is érvényes, ha a base-role cég-szintű (pl. MANAGER).
        // Az aktív értéktári kontextus dönt, nem a magasabb legacy base-role.
        // (A FŐÉRTÉKTÁR nemzeti role NEM tartozik a VAULT_AUTHORITIES-ba → null scope.)
        boolean operatingAsVault = authorities.stream().anyMatch(VAULT_AUTHORITIES::contains);
        if (!operatingAsVault) {
            // Nem értéktári kontextus → cég-szintű vagy egyéb role; nincs terület-szűkítés
            // (a @PreAuthorize governálja a hozzáférést).
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

    /**
     * FK-005/C1: igaz, ha a felhasználó értéktárosként (ERTEKTAR/FOERTEKTAR authority) operál.
     * Codex P1 #846: szét kell választani a „cég-szintű role" (→ minden látható) és a „vault-user
     * region nélkül" (→ CSAK cég-szintű bankok) esetet — a {@link #vaultRegionCodeOrNull()}
     * mindkettőre null-t ad, ezért kell ez a külön jelzés.
     */
    public boolean isVaultContext() {
        return currentAuthorities().stream().anyMatch(VAULT_AUTHORITIES::contains);
    }

    /**
     * FK-005/C1: a vault-felhasználó saját {@code region_code}-ja, VAGY {@code null}, ha
     * cég-szintű role / nem értéktári kontextus / nincs region. A Bank-törzs területi
     * szűréséhez (a bankok közül a cég-szintűek + a saját régióhoz tartozók látszanak).
     */
    @Transactional(readOnly = true)
    public String vaultRegionCodeOrNull() {
        Set<String> authorities = currentAuthorities();
        if (authorities.stream().noneMatch(VAULT_AUTHORITIES::contains)) {
            return null;
        }
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            return null;
        }
        return branchRepository.findById(branchId)
                .map(Branch::getRegionCode)
                .filter(r -> r != null && !r.isBlank())
                .orElse(null);
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

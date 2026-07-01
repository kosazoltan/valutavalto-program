package hu.puzzleir.valuta.security;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import lombok.extern.slf4j.Slf4j;

import java.util.Set;
import java.util.UUID;

/**
 * Territory-scoping feloldó — EGYETLEN forrás az "értéktáros csak a saját vault_territory-ját látja"
 * szabályhoz.
 *
 * <p>A logika korábban az {@code InventoryService} privát másolatában élt (FK-005 / FK-ÉRTÉKTÁR).
 * Az FK-039 (Pénztári készletek nézet, {@code movement-log} RBAC-bővítés) óta az
 * {@code InventoryMovementService} is ugyanezt a szabályt igényli, ezért — hogy a biztonsági
 * logikának NE legyen két, egymástól elsodródható másolata — ide szerveztük ki.</p>
 *
 * <p>Statikus, {@link SecurityUtils}-alapú (a SecurityContextből olvas), így a hívók DI-változás
 * nélkül használhatják, és a meglévő {@code MockedStatic<SecurityUtils>} teszt-minta változatlanul
 * működik.</p>
 */
@Slf4j
public final class TerritoryScopeResolver {

    private TerritoryScopeResolver() {
    }

    /**
     * Territory-scoped szerepkörök: ezek CSAK a saját {@code vault_territory}-jukat látják.
     *
     * <p>A "központi" szerepkörök (foertektar / ugyvezeto / admin) szándékosan NINCSENEK ebben a
     * halmazban — ők mindent látnak (a multi-tenant {@code companyId}-scope-on belül).</p>
     */
    public static final Set<String> TERRITORY_SCOPED_ROLES = Set.of(
            "ertektar", "ERTEKTAR", "ertektaros", "VAULT_KEEPER", "vault_keeper",
            // Codex #1227 P1: az IRODAVEZETO angol enum-formáját (OFFICE_MGR) is fel kell ismerni,
            // különben egy OFFICE_MGR activeRole-lal belépő irodavezető kicsúszna a territory-scope alól.
            "irodavezeto", "IRODAVEZETO", "OFFICE_MGR", "office_mgr"
    );

    /**
     * Az aktuális (effektív = activeOperationalRole, fallback currentRole) szerepkör territory-scoped-e.
     * Defenzív: bármilyen kivétel esetén {@code false} (nincs téves szűkítés scheduler/async kontextusban).
     */
    public static boolean isCurrentRoleTerritoryScoped() {
        try {
            String activeRole = SecurityUtils.getActiveOperationalRole();
            String currentRole = SecurityUtils.getCurrentRole();
            String role = activeRole != null ? activeRole : currentRole;
            return role != null && TERRITORY_SCOPED_ROLES.contains(role);
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Az aktuális felhasználó {@code vault_territory} szűrője (Integer), vagy {@code null} ha:
     * <ul>
     *   <li>központi (nem territory-scoped) role → nincs területi szűrés, VAGY</li>
     *   <li>territory-scoped role, de nincs meghatározható {@code vault_territory} (nincs user branch,
     *       vagy a branch {@code vault_territory_id}-ja null).</li>
     * </ul>
     *
     * <p>A {@code null} kétértelmű (központi VAGY hiányzó territory), ezért FAIL-CLOSED döntéshez a
     * hívó az {@link #isCurrentRoleTerritoryScoped()}-pel együtt használja: ha a role territory-scoped,
     * de ez {@code null}, NE engedj országos hozzáférést.</p>
     */
    public static Integer currentTerritoryFilterOrNull(BranchRepository branchRepository) {
        try {
            String activeRole = SecurityUtils.getActiveOperationalRole();
            String currentRole = SecurityUtils.getCurrentRole();
            String role = activeRole != null ? activeRole : currentRole;
            if (role == null || !TERRITORY_SCOPED_ROLES.contains(role)) {
                return null; // központi role — nincs területi szűrés
            }
            UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
            if (branchId == null) {
                log.warn("territoryFilter: territory-scoped role-nak NINCS user branchId-je → null (defensive)");
                return null;
            }
            return branchRepository.findById(branchId)
                    .map(Branch::getVaultTerritoryId)
                    .orElse(null);
        } catch (Exception e) {
            log.warn("territoryFilter: exception (defensive null fallback): {}", e.getMessage());
            return null;
        }
    }

    /**
     * FK-051 (2026-07-01): a territory-scoped felhasználó által PÉNZTÁR-kontextusban (cash_balance /
     * mozgás) látható branch-ID halmaza a saját {@code region}-je alapján, VAGY {@code null}, ha
     * a role nem territory-scoped (központi — nincs szűrés).
     *
     * <p><b>Miért region, nem vault_territory_id?</b> A pénztárak ({@code is_vault=FALSE}) NEM kapnak
     * {@code vault_territory_id}-t (a V322/V326 backfill elvből csak {@code is_vault=TRUE} branch-re tölt),
     * ezért a korábbi {@code vault_territory_id}-szűrő ({@link #currentTerritoryFilterOrNull}) a régiós
     * értéktárosnak ÜRES pénztár-listát adott (élő országos bug: minden valuta 0). A területi
     * értéktár↔pénztár kapcsolat a {@code region} oszlopon él (pl. 'SZEGED'), ezért a pénztár-nézetek
     * region-scope-ot használnak — összhangban az {@code AccessScopeService.vaultRegionBranchScopeOrNull()}-lel.
     * Az ÉRTÉKTÁRI készlet nézet ({@code currency_stock} / {@code vault_territory}) továbbra is a
     * {@code vault_territory_id}-t használja — az helyes, mert ott a territory az entitás.</p>
     *
     * <p>FAIL-CLOSED: territory-scoped role, de nincs user branch / nincs region → ÜRES halmaz
     * (nem országos hozzáférés). Központi role → {@code null} (nincs szűrés).</p>
     *
     * @return {@code null} = nincs szűrés (központi role); egyébként a saját régió aktív branch-ID-i
     *         (a saját fiók mindig benne). Üres halmaz = fail-closed (nincs meghatározható region).
     */
    public static Set<UUID> currentRegionBranchScopeOrNull(BranchRepository branchRepository) {
        try {
            if (!isCurrentRoleTerritoryScoped()) {
                return null; // központi role — nincs területi szűrés
            }
            UUID companyId = SecurityUtils.getCurrentCompanyId();
            UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
            if (branchId == null || companyId == null) {
                log.warn("regionScope: territory-scoped role-nak NINCS user branch/company → fail-closed (üres)");
                return Set.of();
            }
            String region = branchRepository.findById(branchId).map(Branch::getRegion).orElse(null);
            if (region == null || region.isBlank()) {
                log.warn("regionScope: territory-scoped user branch-nek NINCS region-je → fail-closed (csak saját fiók)");
                return Set.of(branchId);
            }
            Set<UUID> ids = branchRepository.findActiveByCompanyIdAndRegion(companyId, region)
                    .stream()
                    .map(Branch::getId)
                    .collect(java.util.stream.Collectors.toCollection(java.util.HashSet::new));
            ids.add(branchId); // a saját fiók mindig látható
            return ids;
        } catch (Exception e) {
            log.warn("regionScope: exception → fail-closed (üres): {}", e.getMessage(), e);
            return Set.of();
        }
    }
}

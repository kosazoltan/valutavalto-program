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
}

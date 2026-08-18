package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CentralModuleManifestTest {

    @Test
    void foertektarReceivesRateAndVaultModules() {
        List<String> modules = CentralModuleManifest.allowedModules(
                List.of("foertektar"),
                "foertektar",
                null);

        assertThat(modules)
                .contains("rate-maker", "rate-publication", "national-stock", "vault-stocktake")
                .doesNotContain("permission-matrix", "police-requests");
    }

    @Test
    void belsoEllenorReceivesAuditModulesButNotRateMaker() {
        List<String> modules = CentralModuleManifest.allowedModules(
                List.of("belso_ellenor"),
                "belso_ellenor",
                null);

        assertThat(modules)
                .contains("closing-control", "compliance-dashboard", "sanction-list", "transaction-audit")
                .doesNotContain("rate-maker", "worker-registry");
    }

    @Test
    void activeRoleWinsOverInactiveRoles() {
        List<String> modules = CentralModuleManifest.allowedModules(
                List.of("penztar", "ugyvezeto"),
                "penztar",
                null);

        assertThat(modules).isEmpty();
    }

    @Test
    void adminReceivesEveryCentralModule() {
        List<String> modules = CentralModuleManifest.allowedModules(
                List.of("admin"),
                "admin",
                null);

        assertThat(modules)
                .containsExactlyElementsOf(CentralModuleManifest.allModuleIds());
    }

    @Test
    void legacyAdminFallbackReceivesEveryCentralModule() {
        List<String> modules = CentralModuleManifest.allowedModules(
                List.of(),
                null,
                WorkerRole.ADMIN);

        assertThat(modules)
                .containsExactlyElementsOf(CentralModuleManifest.allModuleIds());
    }

    // FK-086 FR-4: a daily-checklist modul a teruleti_vezeto elől elzárt; a három
    // jóváhagyott szerepkör (foertektar, ugyvezeto, belso_ellenor) továbbra is látja.
    @Test
    void dailyChecklistExcludesTeruletiVezetoButKeepsTheThreeApprovedRoles() {
        assertThat(CentralModuleManifest.allowedModules(
                List.of("teruleti_vezeto"), "teruleti_vezeto", null))
                .doesNotContain("daily-checklist");
        for (String role : List.of("foertektar", "ugyvezeto", "belso_ellenor")) {
            assertThat(CentralModuleManifest.allowedModules(List.of(role), role, null))
                    .as("daily-checklist for %s", role)
                    .contains("daily-checklist");
        }
    }
}

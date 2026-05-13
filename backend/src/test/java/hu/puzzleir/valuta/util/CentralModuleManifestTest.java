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
}

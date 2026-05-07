package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AppModeRoleConstantsTest {

    @Test
    void filtersSelectableRolesForRequestedAppMode() {
        List<String> roles = List.of("penztar", "ertektar", "foertektar", "admin");

        assertThat(AppModeRoleConstants.selectableRolesForAppMode(roles, "penztar"))
                .containsExactly("penztar", "foertektar", "admin");
        assertThat(AppModeRoleConstants.selectableRolesForAppMode(roles, "full"))
                .containsExactly("foertektar", "admin");
    }

    @Test
    void returnsValidationMessageForWrongSingleRole() {
        String error = AppModeRoleConstants.validateLoginRolesForAppMode(
                List.of("ertektar"),
                "ertektar",
                false,
                "penztar");

        assertThat(error).contains("nem használható");
    }

    @Test
    void acceptsLowercaseLegacyServerRoles() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("admin", "penztar")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("manager", "full")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("supervisor", "ertektar")).isTrue();
    }

    @Test
    void filtersNullAndBlankRolesBeforeAppModeChecks() {
        assertThat(AppModeRoleConstants.selectableRolesForAppMode(
                java.util.Arrays.asList(null, " ", " ertektar "),
                "ertektar"))
                .containsExactly("ertektar");
    }

    @Test
    void prefersExactLocalRoleForSetupAppMode() {
        assertThat(AppModeRoleConstants.preferredSelectableLocalRoleForAppMode(
                List.of("ugyvezeto", "ertektar"),
                "ertektar"))
                .isEqualTo("ertektar");
    }

    @Test
    void computeValidAppModesIncludesCourierAppMode() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("ertekszallito"),
                null))
                .containsExactly("ertekszallito");
    }

    @Test
    void computeValidAppModesCombinesCourierWithOtherCanonicalModesInStableOrder() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("ertekszallito", "penztar", "ertektar", "teruleti_vezeto", "foertektar"),
                null))
                .containsExactly("penztar", "ertektar", "ertekszallito", "kamera", "full");
    }

    @Test
    void ertekszallitoRoleIsSelectableOnlyInCourierAppMode() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertekszallito"))
                .isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "penztar"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertektar"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "kamera"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "full"))
                .isFalse();
    }

    @Test
    void serverRoleRemainsSelectableInCourierAppForSupervisoryAccess() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("foertektar", "ertekszallito"))
                .isTrue();
    }

    @Test
    void legacyAdminKeepsFullAppModeFallback() {
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.ADMIN))
                .containsExactly("full");
    }
}

package hu.puzzleir.valuta.util;

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
}

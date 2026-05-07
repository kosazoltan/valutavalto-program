package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AppModeRoleConstantsTest {

    @Test
    void computeValidAppModesIncludesCourierAppMode() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("ertekszallito"),
                null))
                .containsExactly("ertekszallito");
    }

    @Test
    void computeValidAppModesIncludesLegacyCourierAppMode() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("COURIER"),
                null))
                .containsExactly("ertekszallito");
    }

    @Test
    void computeValidAppModesNormalizesUppercaseLegacyRoleCodes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("CASHIER", "MANAGER"),
                null))
                .containsExactly("penztar", "ertektar", "full");
    }

    @Test
    void computeValidAppModesFallsBackToLegacyWorkerRoleWhenAssignmentsMissing() {
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.CASHIER))
                .containsExactly("penztar");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.SUPERVISOR))
                .containsExactly("penztar", "ertektar", "ertekszallito", "full");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.MANAGER))
                .containsExactly("penztar", "ertektar", "ertekszallito", "full");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.ADMIN))
                .containsExactly("penztar", "ertektar", "ertekszallito", "full");
    }

    @Test
    void computeValidAppModesNormalizesCanonicalRoleCodes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of(" PENZTAR ", "ERTEKTAR"),
                null))
                .containsExactly("penztar", "ertektar");
    }

    @Test
    void ertekszallitoRoleIsSelectableOnlyInCourierOrSupervisorLocalMode() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertekszallito"))
                .isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "penztar"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertektar"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "full"))
                .isFalse();
    }

    @Test
    void legacyCourierRoleIsSelectableInCourierAppMode() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "ertekszallito"))
                .isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "penztar"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "full"))
                .isFalse();
    }

    @Test
    void legacyWorkerRoleEnumIsSelectableOnlyForItsAllowedAppModes() {
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.CASHIER, "penztar"))
                .isTrue();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.CASHIER, "ertektar"))
                .isFalse();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.CASHIER, "full"))
                .isFalse();

        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.MANAGER, "full"))
                .isTrue();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.MANAGER, "penztar"))
                .isTrue();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.MANAGER, "ertektar"))
                .isTrue();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.MANAGER, "ertekszallito"))
                .isTrue();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.MANAGER, "kamera"))
                .isFalse();
    }

    @Test
    void serverRoleRemainsSelectableInCourierAppForSupervisoryAccess() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("foertektar", "ertekszallito"))
                .isTrue();
    }

    @Test
    void legacyAdminFallbackMatchesSelectableAppModes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.ADMIN))
                .containsExactly("penztar", "ertektar", "ertekszallito", "full");
    }

    @Test
    void legacyWorkerRoleDeniedHelperOnlyAppliesWhenAssignmentsAreMissing() {
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleDeniedForAppMode(
                List.of(), WorkerRole.CASHIER, "ertektar"))
                .isTrue();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleDeniedForAppMode(
                List.of("ertektar"), WorkerRole.CASHIER, "ertektar"))
                .isFalse();
    }
}

package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AppModeRoleConstantsTest {

    @Test
    void filtersSelectableRolesForRequestedAppMode() {
        List<String> roles = List.of("penztar", "ertektar", "foertektar", "admin");

        // Lokalis modban: mindharom lokalis role + szerver role-ok
        assertThat(AppModeRoleConstants.selectableRolesForAppMode(roles, "penztar"))
                .containsExactly("penztar", "ertektar", "foertektar", "admin");
        // Full modban: csak szerver role-ok
        assertThat(AppModeRoleConstants.selectableRolesForAppMode(roles, "full"))
                .containsExactly("foertektar", "admin");
        // Arfolyamkeszito modban: csak foertektar/ugyvezeto/admin
        assertThat(AppModeRoleConstants.selectableRolesForAppMode(roles, "rate-maker"))
                .containsExactly("foertektar", "admin");
    }

    @Test
    void returnsValidationMessageForWrongSingleRole() {
        // ertektar role penztar modban most mar engedelyezett (lokalis cross-role),
        // de full modban nem
        String error = AppModeRoleConstants.validateLoginRolesForAppMode(
                List.of("ertektar"),
                "ertektar",
                false,
                "full");

        assertThat(error).contains("nem használható");
    }

    @Test
    void acceptsLowercaseLegacyServerRoles() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("admin", "penztar")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("manager", "full")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("supervisor", "ertektar")).isTrue();
    }

    @Test
    void centralLeadershipRolesAreSelectableInFullMode() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("teruleti_vezeto", "full")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("biztonsagi_vezeto", "full")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("teruleti_vezeto", "rate-maker")).isFalse();
        // Pénztár-ellenőrzés: a területi vezető Google-lel a PÉNZTÁR funkcióba is beléphet.
        // (Rendezett sorrend: a computeValidAppModes stabilan penztar→kamera→full sorrendben ad vissza.)
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of("teruleti_vezeto"), null))
                .containsExactly("penztar", "kamera", "full");
    }

    @Test
    void leadersCanAccessPenztarForInspection() {
        // FK (Kósa Zoltán 2026-05-26): a vezetők/ellenőrök/értéktáros Google-lel a PÉNZTÁR
        // funkcióba is beléphetnek a pénztárak ellenőrzéséhez.
        for (String role : List.of("ugyvezeto", "foertektar", "teruleti_vezeto", "belso_ellenor", "ertektar")) {
            assertThat(AppModeRoleConstants.computeValidAppModes(List.of(role), null))
                    .as("a(z) %s szerepkör validAppModes-ja tartalmazza a 'penztar'-t", role)
                    .contains("penztar");
        }
    }

    @Test
    void nonInspectionServerRoleDoesNotGetPenztar() {
        // Pl. a bérszámfejtő szerver-role NEM kap pénztár-hozzáférést (nem ellenőr/vezető).
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of("berszamfejto"), null))
                .doesNotContain("penztar");
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
    void computeValidAppModesMapsCourierRoleToLocalOperativeModes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("ertekszallito"),
                null))
                .containsExactly("penztar", "ertektar");
    }

    @Test
    void computeValidAppModesMapsLegacyCourierRoleToLocalOperativeModes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("COURIER"),
                null))
                .containsExactly("penztar", "ertektar");
    }

    @Test
    void computeValidAppModesNeverEmitsErtekszallito() {
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of("ertekszallito"), null))
                .doesNotContain("ertekszallito");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of("COURIER", "penztar"), null))
                .doesNotContain("ertekszallito");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.SUPERVISOR))
                .doesNotContain("ertekszallito");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.MANAGER))
                .doesNotContain("ertekszallito");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.ADMIN))
                .doesNotContain("ertekszallito");
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
                .containsExactly("penztar", "ertektar", "full");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.MANAGER))
                .containsExactly("penztar", "ertektar", "full");
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.ADMIN))
                .containsExactly("penztar", "ertektar", "full", "rate-maker");
    }

    @Test
    void computeValidAppModesNormalizesCanonicalRoleCodes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of(" PENZTAR ", "ERTEKTAR"),
                null))
                .containsExactly("penztar", "ertektar");
    }

    @Test
    void computeValidAppModesCombinesCourierWithOtherCanonicalModesInStableOrder() {
        assertThat(AppModeRoleConstants.computeValidAppModes(
                List.of("ertekszallito", "penztar", "ertektar", "teruleti_vezeto", "foertektar"),
                null))
                .containsExactly("penztar", "ertektar", "kamera", "full", "rate-maker");
    }

    @Test
    void isLocalTerminalAppModeStillAcceptsLegacyErtekszallito() {
        assertThat(AppModeRoleConstants.isLocalTerminalAppMode("ertekszallito")).isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertekszallito"))
                .isTrue();
    }

    @Test
    void courierOnlyWorkerHasSelectableRoleInPenztarAndErtektar() {
        assertThat(AppModeRoleConstants.hasAnySelectableRoleForAppMode(List.of("ertekszallito"), "penztar"))
                .isTrue();
        assertThat(AppModeRoleConstants.hasAnySelectableRoleForAppMode(List.of("ertekszallito"), "ertektar"))
                .isTrue();
        assertThat(AppModeRoleConstants.hasAnySelectableRoleForAppMode(List.of("ertekszallito"), "full"))
                .isFalse();
    }

    @Test
    void ertekszallitoRoleIsSelectableInAnyLocalAppMode() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertekszallito"))
                .isTrue();
        // Lokalis cross-role: kis irodakban ertekszallito penztar/ertektar modban is dolgozhat
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "penztar"))
                .isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "ertektar"))
                .isTrue();
        // Kamera es full: nem
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "kamera"))
                .isFalse();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("ertekszallito", "full"))
                .isFalse();
    }

    @Test
    void legacyCourierRoleIsSelectableInAnyLocalAppMode() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "ertekszallito"))
                .isTrue();
        // Legacy COURIER = ertekszallito lokalis role, cross-modban is engedelyezett
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "penztar"))
                .isTrue();
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "ertektar"))
                .isTrue();
        // Kamera es full: nem
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("COURIER", "kamera"))
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
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.MANAGER, "rate-maker"))
                .isFalse();
        assertThat(AppModeRoleConstants.isLegacyWorkerRoleSelectableForAppMode(WorkerRole.ADMIN, "rate-maker"))
                .isTrue();
    }

    @Test
    void serverRoleRemainsSelectableInCourierAppForSupervisoryAccess() {
        assertThat(AppModeRoleConstants.isRoleSelectableForAppMode("foertektar", "ertekszallito"))
                .isTrue();
    }

    @Test
    void legacyAdminFallbackMatchesSelectableAppModes() {
        assertThat(AppModeRoleConstants.computeValidAppModes(List.of(), WorkerRole.ADMIN))
                .containsExactly("penztar", "ertektar", "full", "rate-maker");
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

    // --- FK-076 (B1 + appMode-szures): grantedRolesForAppMode ---

    /**
     * A hibajelentes alapesete: Fabulya Zsuzsa (prod worker id=273) 13 canonical szerepkorrel,
     * legacy CASHIER enummal. Eddig a tokenbe csak ROLE_CASHIER + ROLE_PENZTAR kerult, ezert az
     * AML threshold / discount apply / HANDLING_FEE mentes 403-at adott, mikozben a UI engedte.
     */
    @Test
    void grantsFullCanonicalRoleSetForCashierInspectionRolesInPenztarMode() {
        List<String> roles = List.of("penztar", "belso_ellenor", "foertektar", "ugyvezeto");

        assertThat(AppModeRoleConstants.grantedRolesForAppMode(roles, "penztar", "penztar"))
                .containsExactly("penztar", "belso_ellenor", "foertektar", "ugyvezeto");
    }

    /**
     * A vedett uzleti szabaly (Kosa Zoltan 2026-05-26): penztargepen veletlenul se lehessen
     * ertektarosként belepni. A grantedRoles claim NEM adhat olyan authority-t, ami az adott
     * appMode-ban nem valaszthato — a `full`/browser szerepkorok a penztar modban is
     * legitim ellenorzesi kor, de a `rate-maker`-only szerepkor mar nem szivarog at.
     */
    @Test
    void filtersOutRolesNotSelectableInTheRequestedAppMode() {
        List<String> roles = List.of("penztar", "ertektar", "foertektar");

        // full (browser): a lokalis penztar/ertektar szerepkorok kiesnek
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(roles, "foertektar", "full"))
                .containsExactly("foertektar");

        // kamera: csak a KAMERA_CANONICAL_ROLES marad — az aktiv role kivetelevel semmi
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(
                List.of("penztar", "ertektar"), null, "kamera"))
                .isEmpty();
    }

    /** Az aktiv role akkor is bekerul, ha a szures kiejtene — azt a login mar validalta. */
    @Test
    void alwaysIncludesActiveRoleEvenWhenFilteredOut() {
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(
                List.of("penztar"), "penztar", "kamera"))
                .containsExactly("penztar");
    }

    /**
     * Hianyzo appMode (sync-engine bootstrap-login) NEM szur — ez megegyezik a
     * `selectableRolesForAppMode` es a login-agi viselkedessel ugyanezen bemenetre.
     */
    @Test
    void doesNotFilterWhenAppModeIsMissing() {
        List<String> roles = List.of("penztar", "ertektar", "foertektar");

        assertThat(AppModeRoleConstants.grantedRolesForAppMode(roles, null, null))
                .containsExactly("penztar", "ertektar", "foertektar");
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(roles, null, "  "))
                .containsExactly("penztar", "ertektar", "foertektar");
    }

    /** Normalizalas + duplikacio-mentesseg: a claim tiszta, kisbetus, egyedi listat hordoz. */
    @Test
    void normalizesAndDeduplicatesGrantedRoles() {
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(
                java.util.Arrays.asList(" Penztar ", "PENZTAR", "penztar", null, ""), "PENZTAR", "penztar"))
                .containsExactly("penztar");
    }

    /** Ures/null bemenet nem dob es ures listat ad (a claim ilyenkor kimarad a tokenbol). */
    @Test
    void returnsEmptyListForNoRoles() {
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(null, null, "penztar")).isEmpty();
        assertThat(AppModeRoleConstants.grantedRolesForAppMode(List.of(), null, "penztar")).isEmpty();
    }
}

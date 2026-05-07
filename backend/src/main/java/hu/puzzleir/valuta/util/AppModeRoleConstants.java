package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Sourcery + Copilot PR #361 follow-up #3: a `validAppModes` szamitas + a canonical
 * role->appMode mapping kozos pontba kerul, hogy NE legyen drift `WorkerService` es
 * `GoogleLoginService` kozott.
 *
 * <p>V181 (PR #363, 2026-05-03): a `teruleti_vezeto` es `biztonsagi_vezeto` canonical
 * role-ok ATKERULTEK a {@link #SERVER_CANONICAL_ROLES} listarol a
 * {@link #KAMERA_CANONICAL_ROLES} listara. Ok NEM ferhetnek hozza a szerver-admin
 * felulethez, csak a helyi penztar modul kameraszoftverehez ("kamera" appMode).</p>
 *
 * <p>Egyetlen helyen a forras-igazsag — modositaskor a hivatkozok automatikusan kovetik.</p>
 */
public final class AppModeRoleConstants {

    private AppModeRoleConstants() {}

    private static final List<String> LEGACY_PENZTAR_ROLES = List.of("cashier");
    private static final List<String> LEGACY_ERTEKTAR_ROLES = List.of("manager", "treasury_manager");
    private static final List<String> LEGACY_ERTEKSZALLITO_ROLES = List.of("courier");
    private static final List<String> LEGACY_SERVER_ROLES = List.of("supervisor", "manager", "admin");

    /**
     * Browser/szerver hozzaferesere jogosult canonical role-ok.
     * V181 (2026-05-03): teruleti_vezeto + biztonsagi_vezeto KIVEVE -> {@link #KAMERA_CANONICAL_ROLES}.
     */
    public static final List<String> SERVER_CANONICAL_ROLES = List.of(
            "ugyvezeto", "foertektar", "irodavezeto", "belso_ellenor",
            "berszamfejto", "penzugyi_vezeto", "irodai_dolgozo",
            "csoportvezeto", "arfolyam_nezo"
    );

    /**
     * V181 (2026-05-03): Kamera-only role-ok. A teruleti vezetok es biztonsagi vezeto
     * csak a helyi penztar modul kameraszoftverehez ferhetnek hozza, NEM a szerverhez.
     */
    public static final List<String> KAMERA_CANONICAL_ROLES = List.of(
            "teruleti_vezeto", "biztonsagi_vezeto"
    );

    /**
     * Egyseges `validAppModes` szamitas a canonical role-codes + worker.role (ADMIN fallback) alapjan.
     *
     * <p>Logika:
     * <ul>
     *   <li>"penztar" canonical role -> "penztar" appMode (penztaros Electron)</li>
     *   <li>"ertektar" canonical role -> "ertektar" appMode (ertektar Electron)</li>
     *   <li>"ertekszallito" canonical role -> "ertekszallito" appMode (ertekszallito Electron)</li>
     *   <li>{@link #KAMERA_CANONICAL_ROLES} barmelyike -> "kamera" appMode (kameraszoftver, NEM browser)</li>
     *   <li>{@link #SERVER_CANONICAL_ROLES} barmelyike -> "full" appMode (browser admin)</li>
     *   <li>WorkerRole.ADMIN enum (legacy fallback) -> "full" appMode</li>
     * </ul>
     * </p>
     */
    public static List<String> computeValidAppModes(List<String> roleCodes, WorkerRole workerRoleEnum) {
        List<String> normalizedRoleCodes = normalizeRoleCodes(roleCodes);
        List<String> validAppModes = new ArrayList<>();
        if (normalizedRoleCodes.contains("penztar")) validAppModes.add("penztar");
        if (normalizedRoleCodes.contains("ertektar")) validAppModes.add("ertektar");
        if (normalizedRoleCodes.contains("ertekszallito")) validAppModes.add("ertekszallito");
        if (hasAny(normalizedRoleCodes, LEGACY_ERTEKSZALLITO_ROLES)
                && !validAppModes.contains("ertekszallito")) {
            validAppModes.add("ertekszallito");
        }
        if (hasAny(normalizedRoleCodes, KAMERA_CANONICAL_ROLES)) {
            validAppModes.add("kamera");
        }
        if (hasAny(normalizedRoleCodes, SERVER_CANONICAL_ROLES)) {
            validAppModes.add("full");
        }
        if (workerRoleEnum == WorkerRole.ADMIN && !validAppModes.contains("full")) {
            validAppModes.add("full");
        }
        return validAppModes;
    }

    /**
     * Role-valasztas fail-closed appMode vedelme.
     *
     * <p>A login valasz aggregalt {@code validAppModes} listaja azt mondja meg, hogy
     * a dolgozo barmely szerepkorevel milyen appokba lephet be. A role-select viszont
     * konkret aktiv role-t veglegesit, ezert itt mar role-szinten kell ellenorizni.
     * A szerver/admin role-ok a lokalis penztar/ertektar appokba is belephetnek
     * felugyeleti celra, de lokalis role (pl. {@code ertektar}) nem valaszthato
     * rossz lokalis appMode-ban vagy browser {@code full} feluleten.</p>
     */
    public static boolean isRoleSelectableForAppMode(String roleCode, String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return true;
        }

        String normalizedAppMode = appMode.trim().toLowerCase();
        String normalizedRole = roleCode == null ? "" : roleCode.trim().toLowerCase();
        if (normalizedRole.isBlank()) {
            return false;
        }

        boolean serverRole = isServerRole(normalizedRole);
        return switch (normalizedAppMode) {
            case "full" -> serverRole;
            case "penztar" -> serverRole
                    || "penztar".equals(normalizedRole)
                    || LEGACY_PENZTAR_ROLES.contains(normalizedRole);
            case "ertektar" -> serverRole
                    || "ertektar".equals(normalizedRole)
                    || LEGACY_ERTEKTAR_ROLES.contains(normalizedRole);
            case "ertekszallito" -> serverRole
                    || "ertekszallito".equals(normalizedRole)
                    || LEGACY_ERTEKSZALLITO_ROLES.contains(normalizedRole);
            case "kamera" -> KAMERA_CANONICAL_ROLES.contains(normalizedRole);
            default -> false;
        };
    }

    public static boolean hasAnySelectableRoleForAppMode(List<String> roleCodes, String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return true;
        }
        if (roleCodes == null || roleCodes.isEmpty()) {
            return false;
        }
        return roleCodes.stream().anyMatch(roleCode -> isRoleSelectableForAppMode(roleCode, appMode));
    }

    private static boolean isServerRole(String normalizedRole) {
        return SERVER_CANONICAL_ROLES.contains(normalizedRole)
                || LEGACY_SERVER_ROLES.contains(normalizedRole);
    }

    private static List<String> normalizeRoleCodes(List<String> roleCodes) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return List.of();
        }

        List<String> normalized = new ArrayList<>();
        for (String roleCode : roleCodes) {
            String value = normalizeRoleCode(roleCode);
            if (!value.isBlank()) {
                normalized.add(value);
            }
        }
        return normalized;
    }

    private static String normalizeRoleCode(String roleCode) {
        return roleCode == null ? "" : roleCode.trim().toLowerCase(Locale.ROOT);
    }

    private static boolean hasAny(List<String> roleCodes, List<String> candidates) {
        return roleCodes.stream().anyMatch(candidates::contains);
    }
}

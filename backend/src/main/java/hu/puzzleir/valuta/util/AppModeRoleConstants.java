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
 * <p>V247 (2026-05-12): a kozponti helyi munkaallomas miatt a `teruleti_vezeto`
 * es `biztonsagi_vezeto` role-ok ujra jogosultak a `full` appMode-ra is, mikozben
 * a kamera appMode tovabbra is megmarad nekik.</p>
 *
 * <p>Egyetlen helyen a forras-igazsag — modositaskor a hivatkozok automatikusan kovetik.</p>
 */
public final class AppModeRoleConstants {

    private AppModeRoleConstants() {}

    private static final List<String> LEGACY_PENZTAR_ROLES = List.of("cashier");
    private static final List<String> LEGACY_ERTEKTAR_ROLES = List.of("manager", "treasury_manager");
    private static final List<String> LEGACY_ERTEKSZALLITO_ROLES = List.of("courier");
    private static final List<String> LEGACY_SERVER_ROLES = List.of("supervisor", "manager", "admin");
    private static final List<String> RATE_MAKER_CANONICAL_ROLES = List.of("foertektar", "ugyvezeto");
    private static final List<String> RATE_MAKER_LEGACY_ROLES = List.of("admin");

    /**
     * Lokalis Electron role-ok: kis irodakban egy dolgozo tobb modban is dolgozhat,
     * ezert barmely lokalis modban (penztar/ertektar/ertekszallito) mindharom
     * lokalis role valaszthato — a felhasznalo lathassa az "Ertektaros" role-t
     * penztar modban is, es forditva.
     */
    private static final List<String> LOCAL_CANONICAL_ROLES = List.of(
            "penztar", "ertektar", "ertekszallito"
    );

    /** True ha a normalized role lokalis (canonical VAGY legacy forma). */
    private static boolean isLocalRole(String normalizedRole) {
        return LOCAL_CANONICAL_ROLES.contains(normalizedRole)
                || LEGACY_PENZTAR_ROLES.contains(normalizedRole)
                || LEGACY_ERTEKTAR_ROLES.contains(normalizedRole)
                || LEGACY_ERTEKSZALLITO_ROLES.contains(normalizedRole);
    }

    /**
     * Browser/szerver/kozponti munkaallomas hozzaferesere jogosult canonical role-ok.
     */
    public static final List<String> SERVER_CANONICAL_ROLES = List.of(
            "ugyvezeto", "foertektar", "irodavezeto", "belso_ellenor",
            "teruleti_vezeto", "biztonsagi_vezeto",
            "berszamfejto", "penzugyi_vezeto", "irodai_dolgozo",
            "csoportvezeto", "arfolyam_nezo"
    );

    /**
     * Kamera appMode role-ok. Ezek a role-ok a kozponti full appMode mellett
     * a helyi penztar modul kameraszoftverehez is hozzaferhetnek.
     */
    public static final List<String> KAMERA_CANONICAL_ROLES = List.of(
            "teruleti_vezeto", "biztonsagi_vezeto"
    );

    /**
     * Egyseges `validAppModes` szamitas a canonical role-codes + worker.role legacy fallback alapjan.
     *
     * <p>Logika:
     * <ul>
     *   <li>"penztar" canonical role -> "penztar" appMode (penztaros Electron)</li>
     *   <li>"ertektar" canonical role -> "ertektar" appMode (ertektar Electron)</li>
     *   <li>"ertekszallito" canonical role -> "ertekszallito" appMode (ertekszallito Electron)</li>
     *   <li>{@link #KAMERA_CANONICAL_ROLES} barmelyike -> "kamera" appMode (kameraszoftver, NEM browser)</li>
     *   <li>{@link #SERVER_CANONICAL_ROLES} barmelyike -> "full" appMode (browser admin)</li>
     *   <li>WorkerRole legacy fallback csak role assignment nelkuli regi dolgozokhoz:
     *       CASHIER -> "penztar", SUPERVISOR/MANAGER/ADMIN -> local supervisory modes + "full"</li>
     * </ul>
     * </p>
     */
    public static List<String> computeValidAppModes(List<String> roleCodes, WorkerRole workerRoleEnum) {
        List<String> normalizedRoleCodes = normalizeRoleCodes(roleCodes);
        List<String> validAppModes = new ArrayList<>();
        if (normalizedRoleCodes.contains("penztar") || hasAny(normalizedRoleCodes, LEGACY_PENZTAR_ROLES)) {
            addIfAbsent(validAppModes, "penztar");
        }
        if (normalizedRoleCodes.contains("ertektar") || hasAny(normalizedRoleCodes, LEGACY_ERTEKTAR_ROLES)) {
            addIfAbsent(validAppModes, "ertektar");
        }
        if (normalizedRoleCodes.contains("ertekszallito") || hasAny(normalizedRoleCodes, LEGACY_ERTEKSZALLITO_ROLES)) {
            addIfAbsent(validAppModes, "ertekszallito");
        }
        if (hasAny(normalizedRoleCodes, KAMERA_CANONICAL_ROLES)) {
            addIfAbsent(validAppModes, "kamera");
        }
        if (hasAny(normalizedRoleCodes, SERVER_CANONICAL_ROLES)
                || hasAny(normalizedRoleCodes, LEGACY_SERVER_ROLES)) {
            addIfAbsent(validAppModes, "full");
        }
        if (hasAny(normalizedRoleCodes, RATE_MAKER_CANONICAL_ROLES)
                || hasAny(normalizedRoleCodes, RATE_MAKER_LEGACY_ROLES)) {
            addIfAbsent(validAppModes, "rate-maker");
        }
        if (normalizedRoleCodes.isEmpty()) {
            if (workerRoleEnum == WorkerRole.CASHIER) {
                addIfAbsent(validAppModes, "penztar");
            }
            if (isLegacyServerWorkerRole(workerRoleEnum)) {
                addIfAbsent(validAppModes, "penztar");
                addIfAbsent(validAppModes, "ertektar");
                addIfAbsent(validAppModes, "ertekszallito");
                addIfAbsent(validAppModes, "full");
                if (workerRoleEnum == WorkerRole.ADMIN) {
                    addIfAbsent(validAppModes, "rate-maker");
                }
            }
        } else if (workerRoleEnum == WorkerRole.ADMIN) {
            addIfAbsent(validAppModes, "full");
            addIfAbsent(validAppModes, "rate-maker");
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
        boolean localRole = isLocalRole(normalizedRole);
        boolean rateMakerRole = RATE_MAKER_CANONICAL_ROLES.contains(normalizedRole)
                || RATE_MAKER_LEGACY_ROLES.contains(normalizedRole);
        return switch (normalizedAppMode) {
            case "full" -> serverRole;
            case "penztar", "ertektar", "ertekszallito" -> serverRole || localRole;
            case "rate-maker" -> rateMakerRole;
            case "kamera" -> KAMERA_CANONICAL_ROLES.contains(normalizedRole);
            default -> false;
        };
    }

    public static boolean hasAnySelectableRoleForAppMode(List<String> roleCodes, String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return true;
        }
        return !selectableRolesForAppMode(roleCodes, appMode).isEmpty();
    }

    public static String canonicalLocalRoleForAppMode(String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return null;
        }
        return switch (appMode.trim().toLowerCase()) {
            case "penztar" -> "penztar";
            case "ertektar" -> "ertektar";
            case "ertekszallito" -> "ertekszallito";
            default -> null;
        };
    }

    public static String preferredSelectableLocalRoleForAppMode(List<String> roleCodes, String appMode) {
        String preferredRole = canonicalLocalRoleForAppMode(appMode);
        if (preferredRole == null) {
            return null;
        }
        return sanitizeRoleCodes(roleCodes).stream()
                .filter(roleCode -> preferredRole.equals(roleCode.toLowerCase()))
                .findFirst()
                .orElse(null);
    }

    public static List<String> selectableRolesForAppMode(List<String> roleCodes, String appMode) {
        List<String> sanitizedRoleCodes = sanitizeRoleCodes(roleCodes);
        if (appMode == null || appMode.isBlank()) {
            return sanitizedRoleCodes;
        }
        return sanitizedRoleCodes.stream()
                .filter(roleCode -> isRoleSelectableForAppMode(roleCode, appMode))
                .toList();
    }

    public static String validateLoginRolesForAppMode(
            List<String> roleCodes,
            String activeRole,
            boolean roleSelectionRequired,
            String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return null;
        }
        if (roleSelectionRequired && !hasAnySelectableRoleForAppMode(roleCodes, appMode)) {
            return "Nincs ebben a programban használható szerepköre.";
        }
        if (activeRole != null && !activeRole.isBlank()
                && !isRoleSelectableForAppMode(activeRole, appMode)) {
            return "Ez a szerepkör nem használható ebben a programban: " + activeRole;
        }
        return null;
    }

    private static List<String> sanitizeRoleCodes(List<String> roleCodes) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return List.of();
        }
        return roleCodes.stream()
                .filter(roleCode -> roleCode != null && !roleCode.isBlank())
                .map(String::trim)
                .toList();
    }

    public static boolean isLegacyWorkerRoleSelectableForAppMode(WorkerRole workerRole, String appMode) {
        if (appMode == null || appMode.isBlank()) {
            return true;
        }
        if (workerRole == null) {
            return false;
        }

        String normalizedAppMode = appMode.trim().toLowerCase(Locale.ROOT);
        boolean serverRole = isLegacyServerWorkerRole(workerRole);
        return switch (normalizedAppMode) {
            case "full" -> serverRole;
            case "penztar" -> serverRole || workerRole == WorkerRole.CASHIER;
            case "ertektar", "ertekszallito" -> serverRole;
            case "rate-maker" -> workerRole == WorkerRole.ADMIN;
            case "kamera" -> false;
            default -> false;
        };
    }

    public static boolean isLegacyWorkerRoleDeniedForAppMode(
            List<String> roleCodes,
            WorkerRole workerRole,
            String appMode
    ) {
        return normalizeRoleCodes(roleCodes).isEmpty()
                && !isLegacyWorkerRoleSelectableForAppMode(workerRole, appMode);
    }

    public static String legacyWorkerRoleDeniedMessage(WorkerRole workerRole) {
        if (workerRole == null) {
            return "Nincs ebben a programban használható szerepköre.";
        }
        return "Ez a szerepkör nem használható ebben a programban: " + workerRole;
    }

    private static boolean isServerRole(String normalizedRole) {
        return SERVER_CANONICAL_ROLES.contains(normalizedRole)
                || LEGACY_SERVER_ROLES.contains(normalizedRole);
    }

    private static boolean isLegacyServerWorkerRole(WorkerRole workerRole) {
        return workerRole == WorkerRole.SUPERVISOR
                || workerRole == WorkerRole.MANAGER
                || workerRole == WorkerRole.ADMIN;
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

    private static void addIfAbsent(List<String> values, String value) {
        if (!values.contains(value)) {
            values.add(value);
        }
    }
}

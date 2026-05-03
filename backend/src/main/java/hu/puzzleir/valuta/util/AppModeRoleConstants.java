package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.entity.WorkerRole;

import java.util.ArrayList;
import java.util.List;

/**
 * Sourcery + Copilot PR #361 follow-up #3: a `validAppModes` szamitas + a canonical
 * role->appMode mapping kozos pontba kerul, hogy NE legyen drift `WorkerService` es
 * `GoogleLoginService` kozott.
 *
 * <p>Egyetlen helyen a forras-igazsag — modositaskor a hivatkozok automatikusan kovetik.</p>
 */
public final class AppModeRoleConstants {

    private AppModeRoleConstants() {}

    /** Browser/szerver hozzaferesere jogosult canonical role-ok. */
    public static final List<String> SERVER_CANONICAL_ROLES = List.of(
            "ugyvezeto", "foertektar", "irodavezeto", "belso_ellenor",
            "teruleti_vezeto", "biztonsagi_vezeto", "berszamfejto",
            "penzugyi_vezeto", "irodai_dolgozo", "csoportvezeto", "arfolyam_nezo"
    );

    /**
     * Egyseges `validAppModes` szamitas a canonical role-codes + worker.role (ADMIN fallback) alapjan.
     *
     * <p>Logika:
     * <ul>
     *   <li>"penztar" canonical role -> "penztar" appMode (penztaros Electron)</li>
     *   <li>"ertektar" canonical role -> "ertektar" appMode (ertektar Electron)</li>
     *   <li>{@link #SERVER_CANONICAL_ROLES} barmelyike -> "full" appMode (browser admin)</li>
     *   <li>WorkerRole.ADMIN enum (legacy fallback) -> "full" appMode</li>
     * </ul>
     * </p>
     */
    public static List<String> computeValidAppModes(List<String> roleCodes, WorkerRole workerRoleEnum) {
        List<String> validAppModes = new ArrayList<>();
        if (roleCodes.contains("penztar")) validAppModes.add("penztar");
        if (roleCodes.contains("ertektar")) validAppModes.add("ertektar");
        if (roleCodes.stream().anyMatch(SERVER_CANONICAL_ROLES::contains)) {
            validAppModes.add("full");
        }
        if (workerRoleEnum == WorkerRole.ADMIN && !validAppModes.contains("full")) {
            validAppModes.add("full");
        }
        return validAppModes;
    }
}

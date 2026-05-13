package hu.puzzleir.valuta.entity;

/**
 * Címletezési optimalizációs stratégiák.
 *
 * <p>v2.0 specifikáció (07_cimletkezeles.md) szerint 7 stratégia, amik a pénztáros
 * által kiadott bankjegyek/érmék készletét optimalizálják különböző üzleti célokra.</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1 (P1-A — Címletezés v2).</p>
 */
public enum OptimizationStrategy {
    /** Mohó algoritmus: legnagyobb címletekkel kezdi (gyors, kevés darabszám). */
    GREEDY("Mohó (legnagyobb címletekkel)"),
    /** Dinamikus programozás: minimális darabszámra optimalizál (lassúbb, optimális). */
    DYNAMIC("Dinamikus (minimum darabszám)"),
    /** Minimum érmekiadás: érme címletekből minél kevesebbet ad. */
    MIN_COINS("Minimum érme"),
    /** Minimum bankjegykiadás: bankjegy címletekből minél kevesebbet. */
    MIN_BANKNOTES("Minimum bankjegy"),
    /** Minimum összes darabszám: érme + bankjegy összesen a legkevesebb. */
    MIN_TOTAL("Minimum összes darabszám"),
    /** Egyedi algoritmus: prioritási sorrend a CONFIG JSON-ben definiálva. */
    CUSTOM("Egyedi (priority order)"),
    /** Fiókspecifikus: branch-szintű készlet-aware optimalizálás. */
    BRANCH_SPECIFIC("Fiókspecifikus");

    private final String displayName;

    OptimizationStrategy(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

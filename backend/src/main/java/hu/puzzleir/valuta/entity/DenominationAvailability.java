package hu.puzzleir.valuta.entity;

/**
 * Címlet elérhetőségi kategória — egyes címleteket gyakran használnak,
 * másokat ritkán (pl. 200 Ft-os érme gyakori, 50 EUR-s bankjegy ritkább).
 *
 * <p>A `Denomination.availability` mezőhöz tartozik, és az
 * `OptimizationStrategy.BRANCH_SPECIFIC` algoritmus használja a
 * címletválasztáshoz.</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1 (P1-A).</p>
 */
public enum DenominationAvailability {
    COMMON("Gyakori"),
    STANDARD("Általános"),
    RARE("Ritka"),
    OBSOLETE("Elavult"),
    SPECIAL("Speciális (gyűjtői)");

    private final String displayName;

    DenominationAvailability(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

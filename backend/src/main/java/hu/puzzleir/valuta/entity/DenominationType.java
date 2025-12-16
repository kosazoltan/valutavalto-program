package hu.puzzleir.valuta.entity;

/**
 * Címlet típusok.
 *
 * Legacy: bankjegy vs érme megkülönböztetés
 */
public enum DenominationType {
    BANKNOTE("Bankjegy"),
    COIN("Érme");

    private final String displayName;

    DenominationType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

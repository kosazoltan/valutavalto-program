package hu.puzzleir.valuta.entity;

/**
 * MNB ajánlás szerinti ügyfél-kockázati fokozat (FS-2).
 * FÜGGETLEN az AML-göngyölés vezérelte Customer.highRiskFlag-től.
 */
public enum CustomerRiskRating {
    LOW("Alacsony"),
    MEDIUM("Közepes"),
    HIGH("Magas");

    private final String displayName;

    CustomerRiskRating(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

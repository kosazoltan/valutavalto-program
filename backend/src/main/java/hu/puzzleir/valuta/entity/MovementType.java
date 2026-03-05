package hu.puzzleir.valuta.entity;

/**
 * Készlet mozgás típusok.
 *
 * Legacy mapping: ERTEKTAR — keszup.dll, atadvet.dll, keszedit.dll
 */
public enum MovementType {
    BANK_WITHDRAW("Bank kivét"),
    BANK_DEPOSIT("Bank befizetés"),
    BRANCH_TRANSFER("Irodák közti szállítás"),
    CORRECTION("Korrekció"),
    INITIAL_STOCK("Nyitó készlet");

    private final String displayName;

    MovementType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

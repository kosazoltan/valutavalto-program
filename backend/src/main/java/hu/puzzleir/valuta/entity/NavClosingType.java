package hu.puzzleir.valuta.entity;

/**
 * NAV zárás típusok.
 */
public enum NavClosingType {
    DAILY("Napi"),
    MONTHLY("Havi"),
    YEARLY("Éves");

    private final String displayName;

    NavClosingType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

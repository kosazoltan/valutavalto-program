package hu.puzzleir.valuta.entity;

/**
 * NAV zárás státuszok.
 */
public enum NavClosingStatus {
    OPEN("Nyitott"),
    CLOSED("Lezárva"),
    SUBMITTED("Beküldve"),
    VERIFIED("Ellenőrizve");

    private final String displayName;

    NavClosingStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

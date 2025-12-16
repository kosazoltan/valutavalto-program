package hu.puzzleir.valuta.entity;

/**
 * Napi munkamenet státusz.
 */
public enum DailySessionStatus {
    OPEN("Nyitva"),
    CLOSED("Zárva"),
    PENDING_CLOSE("Zárás alatt");

    private final String displayName;

    DailySessionStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

package hu.puzzleir.valuta.entity;

/**
 * Készlet mozgás státuszok.
 *
 * Állapotgép: PENDING → APPROVED → IN_TRANSIT → RECEIVED
 *             PENDING → CANCELLED / REJECTED
 */
public enum MovementStatus {
    PENDING("Függőben"),
    APPROVED("Jóváhagyva"),
    IN_TRANSIT("Szállítás alatt"),
    RECEIVED("Fogadva"),
    CANCELLED("Visszavonva"),
    REJECTED("Elutasítva");

    private final String displayName;

    MovementStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

package hu.puzzleir.valuta.entity;

/**
 * Adatgyűjtés státuszok.
 */
public enum DataCollectionStatus {
    PENDING("Függőben"),
    COLLECTING("Gyűjtés folyamatban"),
    COMPLETED("Befejezve"),
    FAILED("Sikertelen");

    private final String displayName;

    DataCollectionStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

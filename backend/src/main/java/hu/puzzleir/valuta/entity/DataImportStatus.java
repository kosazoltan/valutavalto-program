package hu.puzzleir.valuta.entity;

/**
 * Adatimport státuszok.
 */
public enum DataImportStatus {
    PENDING("Függőben"),
    RUNNING("Futó"),
    COMPLETED("Befejezve"),
    FAILED("Sikertelen");

    private final String displayName;

    DataImportStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

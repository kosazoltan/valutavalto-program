package hu.puzzleir.valuta.entity;

/**
 * Adatimport forrás típusok.
 */
public enum DataImportSourceType {
    API("API"),
    FILE("Fájl"),
    FTP("FTP");

    private final String displayName;

    DataImportSourceType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

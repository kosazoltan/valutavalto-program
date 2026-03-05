package hu.puzzleir.valuta.entity;

/**
 * Adatgyűjtés típusok.
 */
public enum DataCollectionType {
    DAILY("Napi"),
    HOURLY("Óránkénti"),
    ON_DEMAND("Igény szerinti");

    private final String displayName;

    DataCollectionType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

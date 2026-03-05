package hu.puzzleir.valuta.entity;

/**
 * Adatimport típusok.
 */
public enum DataImportType {
    DAILY_CLOSING("Napi zárás"),
    INVENTORY("Készlet"),
    TRANSACTIONS("Tranzakciók"),
    RATES("Árfolyamok"),
    FULL("Teljes import");

    private final String displayName;

    DataImportType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

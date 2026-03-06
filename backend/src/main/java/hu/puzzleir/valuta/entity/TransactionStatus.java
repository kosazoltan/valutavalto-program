package hu.puzzleir.valuta.entity;

/**
 * Tranzakció státusz.
 */
public enum TransactionStatus {
    PENDING("Folyamatban"),
    COMPLETED("Befejezett"),
    REVERSED("Sztornózott"),
    FAILED("Sikertelen"),
    CANCELLED("Megszakított"),
    ARCHIVED("Archivált");

    private final String displayName;

    TransactionStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

package hu.puzzleir.valuta.entity;

/**
 * MNB riport típusok.
 *
 * Legacy: MNB adatszolgáltatási kötelezettség — napi/heti/havi/negyedéves/éves.
 */
public enum MnbReportType {
    DAILY("Napi"),
    WEEKLY("Heti"),
    MONTHLY("Havi"),
    QUARTERLY("Negyedéves"),
    YEARLY("Éves");

    private final String displayName;

    MnbReportType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

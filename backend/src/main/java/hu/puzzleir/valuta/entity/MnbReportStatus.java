package hu.puzzleir.valuta.entity;

/**
 * MNB riport státuszok.
 */
public enum MnbReportStatus {
    DRAFT("Vázlat"),
    SUBMITTED("Beküldve"),
    ACKNOWLEDGED("Nyugtázva"),
    ACCEPTED("Elfogadva"),
    REJECTED("Elutasítva");

    private final String displayName;

    MnbReportStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

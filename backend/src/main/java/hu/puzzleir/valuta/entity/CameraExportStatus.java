package hu.puzzleir.valuta.entity;

/**
 * Kamera export kérelem állapotok.
 */
public enum CameraExportStatus {
    REQUESTED,   // Kérelem beadva, jóváhagyásra vár
    APPROVED,    // Jóváhagyva, export indítható
    REJECTED,    // Elutasítva
    EXPORTING,   // Export folyamatban
    COMPLETED,   // Export kész, letölthető
    FAILED       // Export hiba
}

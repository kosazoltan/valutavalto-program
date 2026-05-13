package hu.puzzleir.valuta.entity;

/**
 * Kamera export kérelem állapotok.
 */
public enum CameraExportStatus {
    REQUESTED,                  // Kérelem beadva, jóváhagyásra vár
    AWAITING_SECOND_APPROVAL,   // Sprint 4: első approver OK, 2. approval kell (dual approval flow)
    APPROVED,                   // Jóváhagyva (dual esetén MINDKÉT approver), export indítható
    REJECTED,                   // Elutasítva
    EXPORTING,                  // Export folyamatban
    COMPLETED,                  // Export kész, letölthető
    FAILED                      // Export hiba
}

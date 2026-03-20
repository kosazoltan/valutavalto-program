package hu.puzzleir.valuta.entity;

/**
 * Chain of Custody eseménytípusok.
 */
public enum CustodyEventType {
    EXPORT_REQUESTED,    // Export kérelem létrehozva
    EXPORT_APPROVED,     // Export jóváhagyva
    EXPORT_REJECTED,     // Export elutasítva
    EXPORT_STARTED,      // Export indítva
    EXPORT_COMPLETED,    // Export befejezve
    EXPORT_DOWNLOADED,   // Export letöltve
    PLAYBACK_STARTED,    // Visszanézés indítva
    PLAYBACK_ENDED,      // Visszanézés befejezve
    INTEGRITY_VERIFIED,  // Integritás ellenőrzés sikeres
    INTEGRITY_FAILED,    // Integritás ellenőrzés sikertelen
    EVIDENCE_SEALED,     // Bizonyíték lezárva
    EVIDENCE_UNSEALED    // Bizonyíték feloldva (jogosult által)
}

package hu.puzzleir.valuta.entity;

/**
 * Backup mentés állapota.
 */
public enum BackupStatus {
    /** Mentés folyamatban */
    RUNNING,
    /** Mentés sikeresen befejezve */
    COMPLETED,
    /** Mentés sikertelen */
    FAILED
}

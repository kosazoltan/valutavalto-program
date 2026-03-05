package hu.puzzleir.valuta.entity;

/**
 * Backup mentés típusa.
 */
public enum BackupType {
    /** Teljes adatbázis mentés */
    FULL,
    /** Inkrementális mentés (változások) */
    INCREMENTAL,
    /** Csak kiválasztott táblák exportja */
    TABLES_ONLY
}

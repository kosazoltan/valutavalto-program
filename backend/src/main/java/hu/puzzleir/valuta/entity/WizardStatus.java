package hu.puzzleir.valuta.entity;

/**
 * Zárási varázsló státusza.
 */
public enum WizardStatus {
    IN_PROGRESS,
    COMPLETED,
    FAILED,
    CANCELLED,
    /** FK-065: beragadt munkamenet automatikus lejáratása — nem folytatható. */
    EXPIRED
}

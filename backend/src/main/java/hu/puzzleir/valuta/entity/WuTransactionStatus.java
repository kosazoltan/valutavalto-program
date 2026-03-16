package hu.puzzleir.valuta.entity;

/**
 * Western Union tranzakció státusz enum.
 *
 * Legacy: WUMOZGAS.STATUS — WUNION.DLL státuszok.
 */
public enum WuTransactionStatus {
    /** Tranzakció folyamatban (pl. függő WU utalás). */
    PENDING,
    /** Sikeresen lezárt tranzakció. */
    COMPLETED,
    /** Sztornózott tranzakció (eredeti státus REVERSED). */
    REVERSED,
    /** Sikertelen tranzakció. */
    FAILED
}

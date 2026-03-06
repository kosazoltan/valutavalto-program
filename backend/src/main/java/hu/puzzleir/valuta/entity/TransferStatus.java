package hu.puzzleir.valuta.entity;

/**
 * Irodaközi átadás státuszok — külső kompatibilitási wrapper.
 *
 * A Transfer entity belső enum-ként is definiálja (Transfer.TransferStatus).
 * Ez a top-level enum az import kompatibilitás miatt létezik.
 *
 * Legacy: ATADASI státusz mezők
 */
public enum TransferStatus {
    /** Kérelem benyújtva */
    PENDING,
    /** Jóváhagyva, szállítás alatt */
    APPROVED,
    /** Fogadó iroda átvette */
    RECEIVED,
    /** Visszautasítva */
    REJECTED,
    /** Sztornózva */
    CANCELLED
}

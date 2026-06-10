package hu.puzzleir.valuta.entity;

/**
 * Pénztárgép esemény típusok.
 */
public enum CashRegisterEventType {
    OPEN,
    CLOSE,
    RECEIPT,
    STORNO,
    X_REPORT,
    Z_REPORT,
    CURRENCY_LIST_CLEAR,
    CURRENCY_LIST_SET
}

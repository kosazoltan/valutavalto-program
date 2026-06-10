package hu.puzzleir.valuta.dto.cashregister;

/**
 * Explicit NAV online pénztárgép parancsok.
 *
 * Legacy parancs-prefixek (Anti/camera3 old desktop):
 * - fiscat/AEE|OP: napnyitás
 * - fiscat/AEE|DC|0|0: napzárás
 * - fiscat/AEE|CCL: valuta-lista törlés
 * - fiscat/AEE|CYS: valuta-lista betöltés
 */
public enum CashRegisterCommandType {
    DAY_OPEN,
    DAY_CLOSE,
    CURRENCY_LIST_CLEAR,
    CURRENCY_LIST_SET
}

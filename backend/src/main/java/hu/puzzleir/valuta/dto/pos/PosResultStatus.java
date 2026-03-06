package hu.puzzleir.valuta.dto.pos;

/**
 * POS terminál tranzakció eredmény státusz.
 */
public enum PosResultStatus {
    APPROVED,
    DECLINED,
    ERROR,
    TIMEOUT
}

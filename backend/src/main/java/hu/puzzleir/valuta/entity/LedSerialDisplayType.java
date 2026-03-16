package hu.puzzleir.valuta.entity;

/**
 * LED soros port kijelző típusok — 15+ legacy variáns konszolidálva.
 *
 * Legacy Delphi megfelelők:
 *   STANDARD   → ALAP, MAKEDLL, IRGALMAS
 *   CENTRAL_EU → FERENCES, SZOBOSZLO
 *   EXTENDED   → NOSPEED (14+ valuta)
 *   TEXT_ONLY  → BCSABA, OROS, SPEC8085
 *   MIXED      → UJTIPUS (árfolyam + szöveg)
 *   DUAL_SAME  → DUPLACOM (2 kijelző, azonos tartalom)
 *   DUAL_DIFF  → DUPOTHER (2 kijelző, eltérő tartalom)
 */
public enum LedSerialDisplayType {
    /** EUR/USD/GBP/CHF (legacy: ALAP, MAKEDLL, IRGALMAS) */
    STANDARD,
    /** EUR/USD/CZK/PLN (legacy: FERENCES, SZOBOSZLO) */
    CENTRAL_EU,
    /** 14+ valuta (legacy: NOSPEED) */
    EXTENDED,
    /** Marketing szöveg (legacy: BCSABA, OROS, SPEC8085) */
    TEXT_ONLY,
    /** Árfolyam + szöveg (legacy: UJTIPUS) */
    MIXED,
    /** 2 kijelző, azonos tartalom (legacy: DUPLACOM) */
    DUAL_SAME,
    /** 2 kijelző, eltérő tartalom (legacy: DUPOTHER) */
    DUAL_DIFF
}

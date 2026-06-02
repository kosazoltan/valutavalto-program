package hu.puzzleir.valuta.entity;

/**
 * FK-KEZDÍJ (2026-06-02): a kezelési díj módosításának (override) típusa.
 *
 * <ul>
 *   <li>NONE    — nincs módosítás, a szerver által számolt díj érvényes.</li>
 *   <li>HALF    — felezés (a számolt díj fele).</li>
 *   <li>WAIVED  — elengedés (0 Ft).</li>
 *   <li>SPECIAL — speciális (egyedi) díj — KIZÁRÓLAG ügyvezetői/főértéktárosi jóváhagyással.</li>
 * </ul>
 */
public enum HandlingFeeOverrideType {
    NONE,
    HALF,
    WAIVED,
    SPECIAL
}

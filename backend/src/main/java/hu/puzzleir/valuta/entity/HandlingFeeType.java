package hu.puzzleir.valuta.entity;

/**
 * Kezelési díj típusa.
 *
 * Legacy: _realEzrelek mező a HARDWARE táblában
 * - > 0: ezrelékes rendszer (pl. 5 = 5 ezrelék)
 * - = 0: nincs kezelési díj
 * - < 0: sávos rendszer (a _tranzsav és _kdij tömbök alapján)
 */
public enum HandlingFeeType {
    /** Nincs kezelési díj */
    NONE,
    /** Ezrelékes (per-mille) rendszer: díj = összeg * ezrelék / 1000 */
    PER_MILLE,
    /** Sávos rendszer: összeg sávok szerint fix díj */
    BRACKET
}

package hu.puzzleir.valuta.entity;

/**
 * FK-096: kezelési díj konfiguráció közzétételi állapota.
 *
 * <ul>
 *   <li>{@link #DRAFT} — piszkozat: szerkeszthető, a díjszámítás SOHA nem használja.</li>
 *   <li>{@link #LIVE} — éles: a {@code HandlingFeeService} kizárólag ezt oldja fel
 *       (fail-closed: LIVE sor hiánya 400, soha nem néma 0 Ft).</li>
 * </ul>
 */
public enum FeeConfigStatus {
    /** Piszkozat — még nem éles. */
    DRAFT,
    /** Éles — a díjszámítás ezt használja. */
    LIVE
}

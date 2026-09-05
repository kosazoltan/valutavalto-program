package hu.puzzleir.valuta.dto.retroactiveclosing;

/**
 * FKH-051 (plan D4): classification of one past date for retroactive closing.
 * The frontend branches on this enum, never on message text.
 *
 * <ul>
 *   <li>{@code OPEN} — past day with a non-CLOSED session: the FKH-050 flow can start.</li>
 *   <li>{@code FALSE_CLOSED} — D3 fingerprint: CLOSED, {@code closedByWorker IS NULL},
 *       {@code isRetroactiveClosing} null-or-false (written by the removed day-open
 *       auto-close): reopenable, then the FKH-050 flow can start.</li>
 *   <li>{@code GENUINE_CLOSED} — regularly closed day (worker or retroactive stamp): rejected.</li>
 *   <li>{@code NO_SESSION} — no daily_session row exists for that date.</li>
 *   <li>{@code NOT_PAST} — today or a future date.</li>
 * </ul>
 */
public enum RetroactiveDayKind {
    OPEN,
    FALSE_CLOSED,
    GENUINE_CLOSED,
    NO_SESSION,
    NOT_PAST
}

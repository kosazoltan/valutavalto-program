package hu.puzzleir.valuta.dto.retroactiveclosing;

import java.time.LocalDate;

/**
 * FKH-050 (FR-1): one open past day listed on the retroactive closing entry point.
 * FKH-051 (plan D6): additive {@code kind} — the list is the union of OPEN and
 * false-closed (D3 fingerprint) past days; older clients may treat a missing
 * kind as OPEN.
 */
public record OpenPastDayDto(LocalDate date, RetroactiveDayKind kind) {
}

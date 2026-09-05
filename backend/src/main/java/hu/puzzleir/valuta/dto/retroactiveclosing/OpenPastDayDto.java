package hu.puzzleir.valuta.dto.retroactiveclosing;

import java.time.LocalDate;

/**
 * FKH-050 (FR-1): one open past day listed on the retroactive closing entry point.
 */
public record OpenPastDayDto(LocalDate date) {
}

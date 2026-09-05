package hu.puzzleir.valuta.dto.retroactiveclosing;

import java.time.LocalDate;

/**
 * FKH-051 (plan D4): result of inspecting one typed past date.
 * {@code message} is a Hungarian user-facing explanation per kind; the FE
 * renders it verbatim but branches ONLY on {@code kind}.
 */
public record RetroactiveDayInspectionDto(
        LocalDate date,
        RetroactiveDayKind kind,
        boolean canStart,
        boolean canReprocess,
        String message) {
}

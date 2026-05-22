package hu.puzzleir.valuta.dto.employee;

import java.time.LocalDate;

/**
 * Üzemorvosi vizsgálat DTO (G19, FR-22).
 */
public record EmployeeOccupationalHealthDto(
        Long id,
        String status,
        LocalDate deadlineDate,
        LocalDate examDate,
        String result,
        String restriction
) {
}

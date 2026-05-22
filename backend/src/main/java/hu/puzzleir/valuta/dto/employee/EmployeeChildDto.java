package hu.puzzleir.valuta.dto.employee;

import java.time.LocalDate;

/**
 * Gyermek DTO (G19, FR-20).
 */
public record EmployeeChildDto(
        Long id,
        String name,
        LocalDate birthDate
) {
}

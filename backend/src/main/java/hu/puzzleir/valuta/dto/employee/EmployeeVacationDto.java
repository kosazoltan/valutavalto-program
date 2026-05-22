package hu.puzzleir.valuta.dto.employee;

/**
 * Szabadság (évenkénti) DTO (G19, FR-19).
 */
public record EmployeeVacationDto(
        Long id,
        Integer year,
        Integer broughtForward,
        Integer vacationDays,
        Integer sickLeaveDays,
        Integer takenVacation,
        Integer takenSickLeave,
        Integer sickPayDays,
        Integer unpaidLeaveDays
) {
}

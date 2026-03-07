package hu.puzzleir.valuta.dto.employee;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Dolgozói lista DTO — listázáshoz (kevesebb mező).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeListDto {
    private Long id;
    private String lastName;
    private String firstName;
    private String organizationUnit;
    private String jobTitle;
    private String feorCode;
    private LocalDate employmentStartDate;
    private Boolean active;
}

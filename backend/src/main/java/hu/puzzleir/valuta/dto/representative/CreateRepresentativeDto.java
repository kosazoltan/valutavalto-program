package hu.puzzleir.valuta.dto.representative;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.time.LocalDate;

/**
 * Meghatalmazott létrehozás DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateRepresentativeDto {
    @NotBlank(message = "A név megadása kötelező")
    private String name;

    private String firstName;
    private String lastName;
    private LocalDate birthDate;
    private String birthPlace;
    private String nationalityDid;

    @NotBlank(message = "Az okmányszám megadása kötelező")
    private String documentNumber;

    @NotBlank(message = "Az okmány típus megadása kötelező")
    private String documentType;

    private String documentTypeDid;
    private LocalDate documentValidFrom;
    private LocalDate documentValidTo;

    private String address;
    private String phone;
    private String email;

    private String representativeTypeDid;
    private String relationshipDid;

    @NotNull(message = "Az érvényesség kezdetének megadása kötelező")
    private LocalDate authorizationStart;

    private LocalDate authorizationEnd;
}

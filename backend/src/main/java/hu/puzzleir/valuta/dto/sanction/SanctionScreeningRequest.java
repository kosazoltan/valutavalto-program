package hu.puzzleir.valuta.dto.sanction;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Szankciós szűrés kérés.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionScreeningRequest {

    @NotBlank(message = "A név megadása kötelező")
    private String name;

    private String documentNumber;

    private String dateOfBirth;

    /** Állampolgárság / ország (G4 FATF ország-kockázat szűréshez) — opcionális. */
    private String nationality;
}

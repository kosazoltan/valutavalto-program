package hu.puzzleir.valuta.dto.vaultchecklist;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

/**
 * POST /complete kérés — FR-ZARUI-26 ellenőrző személy adatai + zárás véglegesítése.
 *
 * <p>auditorName és auditorRole mezők kötelezők: üres értékek esetén
 * a service {@link hu.puzzleir.valuta.exception.ValidationException}-t dob.</p>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompleteChecklistRequest {

    /** Ellenőrző személy neve (FR-ZARUI-26). Kötelező, nem lehet üres. */
    @NotBlank(message = "Az ellenőrző személy neve kötelező")
    private String auditorName;

    /** Ellenőrző személy beosztása (FR-ZARUI-26). Kötelező, nem lehet üres. */
    @NotBlank(message = "Az ellenőrző személy beosztása kötelező")
    private String auditorRole;
}

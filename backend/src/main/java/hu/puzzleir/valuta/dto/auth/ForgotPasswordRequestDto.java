package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Elfelejtett jelszo kerelem — a kerelem email-t tartalmaz.
 * A backend valaszol 200-val akkor is, ha az email nem regisztralt
 * (anti-enumeration).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ForgotPasswordRequestDto {
    @NotBlank
    @Email
    private String email;
}
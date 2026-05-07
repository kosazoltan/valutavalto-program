package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Google login request DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GoogleLoginRequestDto {
    @NotBlank
    private String idToken;

    @Size(max = 32, message = "Az appMode max 32 karakter lehet")
    private String appMode;
}

package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Select-role request DTO — második lépés a login-nál,
 * ha a worker-nek több operatív szerepköre van.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SelectRoleRequestDto {

    @NotBlank(message = "Token kötelező")
    private String token;

    @NotBlank(message = "Szerepkör kód kötelező")
    private String roleCode;
}

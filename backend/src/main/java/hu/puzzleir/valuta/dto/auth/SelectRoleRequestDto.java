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

    /**
     * Opcionális kliens appMode (penztar, ertektar, ertekszallito, full).
     * Ha meg van adva, a backend role-szinten ellenőrzi, hogy a kiválasztott
     * role használható-e abban a programban.
     */
    private String appMode;

    public SelectRoleRequestDto(String token, String roleCode) {
        this.token = token;
        this.roleCode = roleCode;
    }
}

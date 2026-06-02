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

    /**
     * FK-ÉRTÉKTÁR (V285, 2026-06-02): capability-flag. Ha a kliens támogatja a kétlépcsős
     * értéktári belépést (dolgozóválasztó + személyes jelszó), true-t küld. Régi kliensek
     * nem küldik (null/false) → a backend a korábbi viselkedéssel intézményi sessiont ad
     * (nem törik el a meglévő login). Új kliensek esetén intézményi fióknál a backend
     * dolgozóválasztót kér (vaultWorkerSelectionRequired = true).
     */
    private Boolean supportsVaultWorkerSelection;
}

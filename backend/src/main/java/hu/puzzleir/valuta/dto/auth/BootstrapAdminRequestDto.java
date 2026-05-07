package hu.puzzleir.valuta.dto.auth;

import hu.puzzleir.valuta.validation.PasswordPolicy;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * First-run setup wizard admin bootstrap request.
 *
 * <p>A pénztáros kliens telepítő wizard 4. lépésében megadott admin
 * hitelesítő adatok a backend-nek. Ez a DTO egyetlen egyszeri hívás
 * payload-ja — a rendszer idempotens blokkolja a második próbálkozást
 * (lásd {@code system_parameter.auth.bootstrap-completed}).</p>
 *
 * <p>Ha a worker már létezik (pl. V69 seed), a jelszava és a role-ja
 * ADMIN-ra íródik át. Ha nem létezik, új worker jön létre CompanyCode
 * cége alatt, az első aktív branch-hez kötve.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BootstrapAdminRequestDto {

    @NotBlank(message = "Cégkód kötelező")
    @Size(max = 32, message = "A cégkód max 32 karakter lehet")
    private String companyCode;

    @NotBlank(message = "Admin felhasználói kód kötelező")
    @Size(max = 10, message = "A felhasználói kód max 10 karakter lehet")
    private String workerCode;

    @NotBlank(message = "Admin név kötelező")
    @Size(max = 100, message = "A név max 100 karakter lehet")
    private String workerName;

    @Email(message = "Érvénytelen email formátum")
    @Size(max = 255, message = "Az email max 255 karakter lehet")
    private String email;

    @NotBlank(message = "Új jelszó kötelező")
    @Size(min = PasswordPolicy.MIN_LENGTH, max = PasswordPolicy.MAX_LENGTH, message = PasswordPolicy.LENGTH_MESSAGE)
    private String newPassword;
}

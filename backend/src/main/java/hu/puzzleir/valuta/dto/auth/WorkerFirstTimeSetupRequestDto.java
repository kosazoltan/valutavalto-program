package hu.puzzleir.valuta.dto.auth;

import hu.puzzleir.valuta.validation.PasswordPolicy;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Worker first-time setup request — a telepito wizard-ban a kivalasztott
 * dolgozo (BORSI, BALI, KASZA stb.) elso jelszavanak beallitasa.
 *
 * <p>Elteres a {@link BootstrapAdminRequestDto}-tol:</p>
 * <ul>
 *   <li>NEM ADMIN role-t ad — megtartja a worker eredeti role-jat</li>
 *   <li>NEM egyszer hasznalhato — minden worker-nek lehet sajat first-time
 *       password setup-ja</li>
 *   <li>Csak akkor engedelyez, ha worker.passwordChangedAt == null
 *       (meg soha nem allitott jelszot) vagy ha currentPassword egyezik</li>
 * </ul>
 *
 * <p>Workflow: a telepito wizard-ban a user kivalasztja a dolgozot
 * a publikus /public/workers?branchCode=X endpoint-rol. Utana beir egy uj
 * jelszot + confirm. Ez a DTO megy a backend-re, ami beallitja a
 * worker.password_hash-t.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WorkerFirstTimeSetupRequestDto {

    @NotBlank(message = "Cegkod kotelezo")
    @Size(max = 32, message = "A cegkod max 32 karakter lehet")
    private String companyCode;

    @NotBlank(message = "Dolgozoi azonosito (workerCode) kotelezo")
    @Size(max = 10, message = "A workerCode max 10 karakter lehet")
    private String workerCode;

    @NotBlank(message = "Uj jelszo kotelezo")
    @Size(min = PasswordPolicy.MIN_LENGTH, max = PasswordPolicy.MAX_LENGTH, message = PasswordPolicy.LENGTH_MESSAGE)
    private String newPassword;

    /**
     * A jelenlegi vagy kezdo worker jelszo. Lezart bootstrap utan kotelezo,
     * ha a workerhez mar tartozik hash; csak a friss elso telepites engedi
     * elhagyni.
     */
    @Size(max = PasswordPolicy.MAX_LENGTH, message = PasswordPolicy.MAX_LENGTH_MESSAGE)
    private String currentPassword;
}

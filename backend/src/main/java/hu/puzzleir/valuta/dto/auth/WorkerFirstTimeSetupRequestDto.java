package hu.puzzleir.valuta.dto.auth;

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
    @Size(min = 8, max = 128, message = "A jelszo 8 es 128 karakter kozott legyen")
    private String newPassword;

    /**
     * A jelenlegi vagy kezdo worker jelszo. Lezart bootstrap utan kotelezo,
     * ha a workerhez mar tartozik hash; csak a friss elso telepites engedi
     * elhagyni.
     */
    @Size(max = 128, message = "A jelszo max 128 karakter")
    private String currentPassword;

    @Size(max = 32, message = "Az appMode max 32 karakter lehet")
    private String appMode;

    /**
     * F-001 fix: admin által kiállított, egyszer használatos setup-token. A bootstrap-lezárt
     * utáni null-hash (teljes reset) setuphoz KÖTELEZŐ — enélkül a publikus endpointon a
     * worker-kód ismeretében fiókátvétel lenne lehetséges. A kezdeti (pre-bootstrap) telepítés
     * és a már hash-sel rendelkező (seed/aktív) workerek setupja nem igényli.
     */
    @Size(max = 128, message = "A setup-token max 128 karakter")
    private String setupToken;

    public WorkerFirstTimeSetupRequestDto(
            String companyCode,
            String workerCode,
            String newPassword,
            String currentPassword) {
        this.companyCode = companyCode;
        this.workerCode = workerCode;
        this.newPassword = newPassword;
        this.currentPassword = currentPassword;
    }
}

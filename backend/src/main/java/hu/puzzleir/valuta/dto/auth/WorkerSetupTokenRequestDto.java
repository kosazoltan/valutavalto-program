package hu.puzzleir.valuta.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Admin kérés egy worker first-time setup-tokenjének kiállítására (F-001 fix).
 *
 * <p>Hitelesített admin/supervisor hívja, hogy egy konkrét (cégkód + dolgozói kód)
 * workerhez egyszer használatos, lejáró setup-tokent generáljon. A token a válaszban
 * EGYSZER jelenik meg; ezt kell a kollégának eljuttatni.</p>
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WorkerSetupTokenRequestDto {

    @NotBlank(message = "Cegkod kotelezo")
    @Size(max = 32, message = "A cegkod max 32 karakter lehet")
    private String companyCode;

    @NotBlank(message = "Dolgozoi azonosito (workerCode) kotelezo")
    @Size(max = 10, message = "A workerCode max 10 karakter lehet")
    private String workerCode;
}

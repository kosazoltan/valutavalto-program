package hu.puzzleir.valuta.dto.setup;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SetupGoogleIdentifyRequestDto {

    @NotBlank
    private String idToken;

    @NotBlank
    private String companyCode;

    private String appMode;

    /**
     * Megosztott branch emailnel a wizard ezen keresztul mondja meg,
     * hogy a listabol melyik dolgozot valasztotta ki a felhasznalo.
     */
    private String selectedWorkerCode;

    /**
     * Ha true, a validalt Google sub rogzitheto a kiválasztott workerhez.
     * Egyedi worker-emailnel a binding ugyanazt a szabalykeszletet koveti,
     * mint a normal Google login.
     */
    @Builder.Default
    private Boolean bindGoogleSubject = Boolean.FALSE;
}

package hu.puzzleir.valuta.dto.customer;

import hu.puzzleir.valuta.entity.CustomerRiskRating;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/** FS-2: ügyfél MNB kockázati besorolásának állítása (compliance-művelet, audit-köteles). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SetCustomerRiskRatingRequest {

    @NotNull(message = "A kockázati besorolás kötelező")
    private CustomerRiskRating riskRating;

    @NotBlank(message = "A besorolás indoka kötelező")
    @Size(max = 400, message = "Az indok legfeljebb 400 karakter lehet")
    private String reason;
}

package hu.puzzleir.valuta.dto.customer;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Pmt. 30.§ (1) szerinti manuális EDD-jelölés kérése (V.2.7 c — V309/V310).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarkCustomerEddRequest {

    @NotBlank(message = "Az EDD-jelölés indoka kötelező")
    @Size(max = 400, message = "Az indok legfeljebb 400 karakter lehet")
    private String reason;
}

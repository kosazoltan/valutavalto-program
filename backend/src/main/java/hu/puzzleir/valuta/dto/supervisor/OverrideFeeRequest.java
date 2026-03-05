package hu.puzzleir.valuta.dto.supervisor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OverrideFeeRequest {
    @NotNull(message = "Tranzakció ID kötelező!")
    private Long transactionId;

    @NotNull(message = "Új díj összeg kötelező!")
    private BigDecimal newFee;

    @NotBlank(message = "Indoklás kötelező!")
    private String reason;
}

package hu.puzzleir.valuta.dto.supervisor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OverrideRateRequest {
    @NotNull(message = "Iroda ID kötelező!")
    private UUID branchId;

    @NotBlank(message = "Valutanem kötelező!")
    private String currency;

    @NotNull(message = "Új vételi árfolyam kötelező!")
    private BigDecimal newBuyRate;

    @NotNull(message = "Új eladási árfolyam kötelező!")
    private BigDecimal newSellRate;

    @NotBlank(message = "Indoklás kötelező!")
    private String reason;
}

package hu.puzzleir.valuta.dto.rateapproval;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.math.BigDecimal;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RequestRateChangeDto {
    @NotNull
    private UUID branchId;

    @NotBlank
    private String currencyCode;

    @NotNull
    private BigDecimal newBuyRate;

    @NotNull
    private BigDecimal newSellRate;

    private String reason;
}

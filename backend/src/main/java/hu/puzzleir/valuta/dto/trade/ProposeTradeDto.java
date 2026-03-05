package hu.puzzleir.valuta.dto.trade;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ProposeTradeDto {
    private UUID fromBranchId;
    private UUID toBranchId;
    private String currencyCode;
    private BigDecimal amount;
    private BigDecimal rate;
    private String notes;
}

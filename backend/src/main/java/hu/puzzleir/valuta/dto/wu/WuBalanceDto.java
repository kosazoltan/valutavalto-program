package hu.puzzleir.valuta.dto.wu;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuBalanceDto {
    private UUID id;
    private UUID branchId;
    private BigDecimal usdBalance;
    private BigDecimal hufBalance;
    private String lastReceiptSell;
    private String lastReceiptBuy;
    private String lastReceiptCustomerIn;
    private String lastReceiptCustomerOut;
    private LocalDateTime updatedAt;
}

package hu.puzzleir.valuta.dto.inventory;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Napi készlet egyenleg DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryBalanceDto {
    private UUID branchId;
    private String currencyCode;
    private BigDecimal openingBalance;
    private BigDecimal closingBalance;
    private BigDecimal totalIn;
    private BigDecimal totalOut;
    private String date;
}

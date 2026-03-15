package hu.puzzleir.valuta.dto.treasury;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Altalanos aggregacios DTO treasury osszesitesekhez.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TreasuryAggregateDto {
    private String id;
    private String code;
    private String name;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private int transactionCount;
    private int branchCount;
}

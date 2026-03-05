package hu.puzzleir.valuta.dto.treasury;

import lombok.*;
import java.math.BigDecimal;
import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TreasuryDashboardDto {
    /**
     * Összesített forgalom valutánként: Map<currencyCode, CurrencyTotals>
     */
    private Map<String, CurrencyTotalsDto> currencyTotals;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private Integer totalTransactionCount;
    private Integer branchCount;
}

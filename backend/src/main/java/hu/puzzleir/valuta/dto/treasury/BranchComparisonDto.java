package hu.puzzleir.valuta.dto.treasury;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchComparisonDto {
    private String branchId;
    private String branchCode;
    private String branchName;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private Integer transactionCount;
}

package hu.puzzleir.valuta.dto.report;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DailyReportDto {
    private Long id;
    private String branchId;
    private String branchCode;
    private String branchName;
    private String reportDate;
    private Boolean submitted;
    private String submittedAt;
    private Long submittedById;
    private String submittedByName;
    private String reportData;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private Integer transactionCount;
    private String createdAt;
}

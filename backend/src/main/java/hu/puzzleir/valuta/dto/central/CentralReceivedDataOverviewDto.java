package hu.puzzleir.valuta.dto.central;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CentralReceivedDataOverviewDto {
    private LocalDate reportDate;
    private Integer totalBranches;
    private Integer receivedReports;
    private Integer submittedReports;
    private Integer missingReports;
    private Integer warningClosings;
    private Integer criticalClosings;
    private Integer totalTransactions;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private LocalDateTime generatedAt;
    private List<CentralReceivedDataRowDto> rows;
}

package hu.puzzleir.valuta.dto.darius;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * Darius havi összesítő DTO.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DariusMonthlyDto {
    private int year;
    private int month;
    private int totalReports;
    private int acknowledgedCount;
    private int failedCount;
    private int pendingCount;

    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalHandlingFeeHuf;
    private Integer totalTransactionCount;

    private List<DariusDailyReportDto> dailyReports;
}

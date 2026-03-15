package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;
import java.util.List;

@Data
@Builder
public class ConsolidatedReportResponseDto {
    private String dateFrom;
    private String dateTo;
    private List<BranchDailyReportDto> branches;
    private TotalsDto totals;

    @Data
    @Builder
    public static class TotalsDto {
        private int totalTransactions;
        private int totalSellCount;
        private int totalBuyCount;
        private long totalHufTurnover;
        private long totalFees;
    }
}

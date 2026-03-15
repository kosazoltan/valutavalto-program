package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class BranchDailyReportDto {
    private String branchCode;
    private String branchName;
    private String date;
    private int sellCount;
    private int buyCount;
    private int totalTransactions;
    private long sellHufVolume;
    private long buyHufVolume;
    private long totalHufTurnover;
    private long totalFees;
}

package hu.puzzleir.valuta.dto.dashboard;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class DashboardSummaryDto {
    private BigDecimal todayVolume;
    private int activeBranches;
    private int openTransactions;
    private int alertCount;
    private Map<String, BigDecimal> currencyVolumes;
    private List<RecentTransactionDto> recentTransactions;
    private List<BranchSyncStatusDto> branchSyncStatuses;

    @Data @NoArgsConstructor @AllArgsConstructor @Builder
    public static class RecentTransactionDto {
        private Long id;
        private String receiptNumber;
        private String type;
        private String currencyCode;
        private BigDecimal amount;
        private BigDecimal hufAmount;
        private String cashierName;
        private String createdAt;
    }

    @Data @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BranchSyncStatusDto {
        private String branchCode;
        private String branchName;
        private String lastSyncAt;
        private String status;
    }
}

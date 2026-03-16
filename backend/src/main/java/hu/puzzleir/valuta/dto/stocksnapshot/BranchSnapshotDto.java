package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchSnapshotDto {
    private UUID branchId;
    private String branchName;
    private String branchCode;
    private LocalDateTime lastUpdated;
    private List<CurrencyStockDetailDto> currencies;
    private WuBalanceDetailDto wuBalance;
    private List<ReservationSummaryDto> reservations;
}

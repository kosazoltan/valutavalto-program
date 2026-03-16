package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchStockTotalsDto {
    private List<CurrencyStockDetailDto> currencies;
    private WuBalanceDetailDto wuBalance;
    private List<ReservationSummaryDto> reservations;
}

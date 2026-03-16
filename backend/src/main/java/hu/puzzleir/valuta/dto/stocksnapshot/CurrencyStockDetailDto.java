package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CurrencyStockDetailDto {
    private String currencyCode;
    private long stock;
    private long stockHuf;
    private long dailyBuy;
    private long dailyBuyHuf;
    private long dailySell;
    private long dailySellHuf;
}

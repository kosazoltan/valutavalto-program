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
    /** FK-093: van-e cash_balance sor az adott fiók-deviza párra (nem azonos stock>0-val). */
    private boolean hasBalance;
}

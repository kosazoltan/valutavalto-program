package hu.puzzleir.valuta.dto.treasury;

import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CurrencyTotalsDto {
    private String currencyCode;
    private String currencyName;
    private BigDecimal totalStock;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
}

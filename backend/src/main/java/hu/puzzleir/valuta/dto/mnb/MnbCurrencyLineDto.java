package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

import java.math.BigDecimal;

/**
 * MNB riport valutánkénti sor DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbCurrencyLineDto {
    private String currencyCode;
    private BigDecimal buyAmount;
    private BigDecimal sellAmount;
    private BigDecimal buyHuf;
    private BigDecimal sellHuf;
    private BigDecimal avgBuyRate;
    private BigDecimal avgSellRate;
    private int transactionCount;
}

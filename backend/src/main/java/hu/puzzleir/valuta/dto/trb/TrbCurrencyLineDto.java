package hu.puzzleir.valuta.dto.trb;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Egy valutanem sora a TRB exportban.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrbCurrencyLineDto {
    private String currencyCode;
    private BigDecimal sold;
    private BigDecimal bought;
    private BigDecimal bankCardAmount;
    private BigDecimal bankCardFee;
}

package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FKH-036 FR-1: valutánkénti záró egyenleg nézet — az esti (EVENING) címletezési
 * egyenlegek összege. Ugyanaz a forrás, amit a ClosingWizardService.loadPhysicalCounts
 * használ, így az oldal és a záró-kapu nem térhet el egymástól.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class BalanceView {
    private String currency;
    private BigDecimal amount;
}

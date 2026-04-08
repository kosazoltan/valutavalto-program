package hu.puzzleir.valuta.dto.trb;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Banki forgalom sor (valutanemenként felvett/kifizetett KP).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrbBankFlowLineDto {
    private String currencyCode;
    private BigDecimal withdrawn;
    private BigDecimal deposited;
}

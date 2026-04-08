package hu.puzzleir.valuta.dto.treasury;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Bankforgalom összesítő — egy valutanem, egy cég.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BankTurnoverDto {
    private String companyCode;
    private String companyName;
    private String currencyCode;
    private BigDecimal withdrawnAmount;
    private BigDecimal depositedAmount;
    private BigDecimal netFlow;
}

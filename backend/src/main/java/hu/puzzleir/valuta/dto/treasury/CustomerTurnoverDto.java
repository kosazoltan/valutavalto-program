package hu.puzzleir.valuta.dto.treasury;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Ügyfélforgalom összesítő — egy iroda, egy valutanem.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerTurnoverDto {
    private String branchCode;
    private String branchName;
    private String currencyCode;
    private BigDecimal soldAmount;
    private BigDecimal boughtAmount;
    private int sellCount;
    private int buyCount;
}

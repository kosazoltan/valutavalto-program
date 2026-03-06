package hu.puzzleir.valuta.dto.calculator;

import lombok.*;

import java.math.BigDecimal;

/**
 * Deviza átváltás kalkulátor eredmény DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CalculationResultDto {

    private String fromCurrency;
    private String toCurrency;
    private BigDecimal fromAmount;
    private BigDecimal toAmount;
    private BigDecimal appliedRate;
    private BigDecimal spread;
    private BigDecimal commission;
    private String direction;
    private String roundingInfo;
}

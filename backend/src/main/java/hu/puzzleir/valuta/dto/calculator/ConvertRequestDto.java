package hu.puzzleir.valuta.dto.calculator;

import lombok.*;

import java.math.BigDecimal;

/**
 * Deviza átváltási kérés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConvertRequestDto {

    private String fromCurrency;
    private String toCurrency;
    private BigDecimal amount;
    private String direction; // BUY or SELL
}

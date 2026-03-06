package hu.puzzleir.valuta.dto.rounding;

import lombok.*;

import java.math.BigDecimal;

/**
 * Kerekítési szabály DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoundingRuleDto {

    private Long id;
    private String currencyCode;
    private BigDecimal precisionValue;
    private BigDecimal smallThreshold;
    private BigDecimal largeThreshold;
    private String smallRounding;
    private String largeRounding;
}

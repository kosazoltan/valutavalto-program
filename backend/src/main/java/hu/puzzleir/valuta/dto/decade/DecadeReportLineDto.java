package hu.puzzleir.valuta.dto.decade;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Dekád haszon valutánkénti bontás DTO.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DecadeReportLineDto {
    private UUID id;
    private String currencyCode;
    private BigDecimal openingBalance;
    private BigDecimal openingMnbRate;
    private BigDecimal openingValueHuf;
    private BigDecimal closingBalance;
    private BigDecimal closingMnbRate;
    private BigDecimal closingValueHuf;
    private BigDecimal profitHuf;
}

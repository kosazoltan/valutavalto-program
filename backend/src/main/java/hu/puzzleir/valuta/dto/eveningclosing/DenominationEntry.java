package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Címletezés bejegyzés a napi adatcsomagban.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DenominationEntry {
    private String currencyCode;
    private String denominationType;
    private BigDecimal denominationValue;
    private Integer quantity;
    private BigDecimal totalAmount;
}

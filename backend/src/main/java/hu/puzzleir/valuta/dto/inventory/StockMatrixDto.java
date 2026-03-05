package hu.puzzleir.valuta.dto.inventory;

import lombok.*;
import java.math.BigDecimal;
import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StockMatrixDto {
    /**
     * Map<branchId, Map<currencyCode, amount>>
     */
    private Map<String, Map<String, BigDecimal>> matrix;
}

package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Kezelési díj összesítő a napi adatcsomagban.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class HandlingFeeSummary {
    private BigDecimal totalHandlingFee;
    private int transactionCount;
    private BigDecimal averageFee;
    private BigDecimal maxFee;
    private BigDecimal minFee;
}

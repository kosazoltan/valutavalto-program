package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Napi árfolyam pillanatfelvétel a napi adatcsomagban.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class RateSnapshot {
    private String currencyCode;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private BigDecimal midRate;
    private String source;
}

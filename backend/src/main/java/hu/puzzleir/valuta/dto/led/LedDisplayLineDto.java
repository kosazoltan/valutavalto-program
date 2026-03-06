package hu.puzzleir.valuta.dto.led;

import lombok.*;

import java.math.BigDecimal;

/**
 * LED kijelzőn megjelenő egy sor (valuta árfolyam).
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class LedDisplayLineDto {
    private String currencyCode;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private Integer unit;
}

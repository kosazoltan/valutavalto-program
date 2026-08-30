package hu.puzzleir.valuta.dto.levy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FK-099 — egy típus-csoport (Vétel / Eladás / Konverzió) öt alkomponense
 * egy pénztár-nap sorban.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TypeGroupDto {

    /** Normál (küszöb alatti) tételek alap-illetéke. */
    private BigDecimal normalBaseLevy;

    /** Normál tételek kiegészítő illetéke. */
    private BigDecimal normalSupplementLevy;

    /** Küszöb feletti tételek darabszáma. */
    private long aboveThresholdCount;

    /** Küszöb feletti tételek alap-illetéke. */
    private BigDecimal aboveThresholdBaseLevy;

    /** Küszöb feletti tételek kiegészítő illetéke. */
    private BigDecimal aboveThresholdSupplementLevy;
}

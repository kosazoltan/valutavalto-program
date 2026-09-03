package hu.puzzleir.valuta.dto.levy;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FK-099 FR-12/13/14 — havi cég-szintű panel: önálló vétel/eladás darabszámok,
 * ügyfélszám, küszöb alatti és feletti HUF-forgalom. A konverzió SZÁNDÉKOSAN
 * kimarad (ticket TBD-3 OUT).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonthlySummaryDto {

    /** Önálló vétel tranzakciók darabszáma (nem distinct ügyfél). */
    private long buyCount;

    /** Önálló eladás tranzakciók darabszáma (nem distinct ügyfél). */
    private long sellCount;

    /** Distinct nem-üres customerId az önálló vétel/eladás tételeken. */
    private long customerCount;

    /** Küszöb alatti önálló vétel HUF-forgalom. */
    private BigDecimal belowThresholdBuyHuf;

    /** Küszöb alatti önálló eladás HUF-forgalom. */
    private BigDecimal belowThresholdSellHuf;

    /** Küszöb feletti önálló vétel HUF-forgalom. */
    private BigDecimal aboveThresholdBuyHuf;

    /** Küszöb feletti önálló eladás HUF-forgalom. */
    private BigDecimal aboveThresholdSellHuf;

    /** Combined below-threshold Buy+Sell HUF (derived; conversion excluded). */
    private BigDecimal belowThresholdTotalHuf;

    /** Combined above-threshold Buy+Sell HUF (derived; conversion excluded). */
    private BigDecimal aboveThresholdTotalHuf;

    /** Additive transaction count: buyCount + sellCount (conversion excluded). */
    private long totalCount;
}

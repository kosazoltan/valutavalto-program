package hu.puzzleir.valuta.dto.competitor;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Egy versenyhely MAI bevitt versenytárs-árfolyama egy valutára — a beíró oldal előtöltéséhez
 * (hogy az árfolyam néző lássa/módosíthassa, amit ma már beírt).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompetitorTodayRateDto {
    private Long currencyId;
    private String currencyCode;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
}

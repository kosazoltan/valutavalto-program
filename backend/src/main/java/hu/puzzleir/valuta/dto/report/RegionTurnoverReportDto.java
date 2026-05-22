package hu.puzzleir.valuta.dto.report;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

/**
 * G23 (EXCMD b8-forgalom FR-13..15): körzet-szintű havi forgalmi/trend riport.
 *
 * <p>Régiónként (körzet) összesíti a havi forgalmat (vétel/eladás darab + HUF),
 * az egyedi ügyfelek számát, az aktív (forgalmas) napok számát és az átlagos
 * napi forgalmat, valamint kiszámítja a trend%-ot az előző hónaphoz képest.</p>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegionTurnoverReportDto {

    private String yearMonth;                 // "2026-03"
    private String previousYearMonth;         // "2026-02"

    @Builder.Default
    private List<RegionLineDto> regions = List.of();

    // Összesítők (minden régió együtt)
    @Builder.Default private BigDecimal totalTurnoverHuf = BigDecimal.ZERO;
    @Builder.Default private BigDecimal previousTotalTurnoverHuf = BigDecimal.ZERO;
    @Builder.Default private BigDecimal totalTrendPercent = BigDecimal.ZERO;

    /**
     * Egy körzet havi forgalmi sora.
     */
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class RegionLineDto {
        private String regionCode;            // pl. "20" (Szeged körzet), null → "EGYÉB"
        @Builder.Default private long buyCount = 0;
        @Builder.Default private long sellCount = 0;
        @Builder.Default private BigDecimal buyHuf = BigDecimal.ZERO;
        @Builder.Default private BigDecimal sellHuf = BigDecimal.ZERO;
        @Builder.Default private BigDecimal totalTurnoverHuf = BigDecimal.ZERO;
        @Builder.Default private long distinctCustomers = 0;
        @Builder.Default private long activeDays = 0;
        @Builder.Default private BigDecimal avgDailyTurnoverHuf = BigDecimal.ZERO;
        // Trend az előző hónaphoz képest
        @Builder.Default private BigDecimal previousTurnoverHuf = BigDecimal.ZERO;
        @Builder.Default private BigDecimal trendPercent = BigDecimal.ZERO;
    }
}

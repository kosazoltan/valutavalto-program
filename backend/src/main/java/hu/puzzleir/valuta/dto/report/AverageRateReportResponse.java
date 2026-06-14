package hu.puzzleir.valuta.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * FK-027 — Átlag árfolyam riport pivot-struktúra (legacy ATLAGARF / Atlagarfolyam.xls parity).
 *
 * <p>Sorok = valuták (mind a 22, rögzített display_order sorrendben), oszlopcsoportok =
 * terület / fiók / összesítő. Minden oszlopcsoport 4 értéket hordoz: Vétel Árfolyam,
 * Vétel Összeg, Eladás Árfolyam, Eladás Összeg (Vétel és Eladás MINDIG párhuzamosan).</p>
 *
 * <ul>
 *   <li>"Összes iroda": {@code columnGroups} = 8 REGION + 1 TOTAL ("EXCLUSIVE BEST CHANGE ZRT")</li>
 *   <li>Egy konkrét pénztár szűrve: {@code columnGroups} = 1 BRANCH elem</li>
 * </ul>
 *
 * <p>Súlyozott átlag = SUM(hufAmount) / SUM(currencyAmount) (HUF-súlyozott, nem aritmetikai).
 * Csak {@code is_vault=FALSE} pénztárak, csak COMPLETED + financialEffective BUY/SELL tételek
 * (a sztornózott — REVERSED — és a parent CONVERSION sorok kimaradnak).</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AverageRateReportResponse {

    private LocalDate periodStart;
    private LocalDate periodEnd;

    /** Oszlopcsoportok sorrendben (8 terület + összesítő, vagy 1 fiók). */
    private List<ColumnGroup> columnGroups;

    /** Valuta-sorok (mind a 22, display_order szerint). */
    private List<CurrencyRow> currencyRows;

    public enum GroupType { REGION, TOTAL, BRANCH }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ColumnGroup {
        /** Kulcs a {@code CurrencyRow.values} map-hez (pl. "SZEKSZARD", "total", fiók-kód). */
        private String groupCode;
        /** Megjelenítendő név (pl. "Szekszárd körzet", "EXCLUSIVE BEST CHANGE ZRT", fiók-név). */
        private String groupName;
        private GroupType groupType;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CurrencyRow {
        private String currencyCode;
        /** Kulcs = {@link ColumnGroup#groupCode}; minden oszlopcsoportra egy érték-négyes. */
        private Map<String, ColumnValues> values;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ColumnValues {
        private BigDecimal buyAvgRate;
        private BigDecimal buySumAmount;
        private BigDecimal sellAvgRate;
        private BigDecimal sellSumAmount;
    }
}

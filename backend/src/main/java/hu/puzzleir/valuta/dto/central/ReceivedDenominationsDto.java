package hu.puzzleir.valuta.dto.central;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FK-111 / FK-112: closing-time denomination stock matrix behind the "Keszletek, cimletek" tab
 * of the received-data page (legacy: PTARKESZ / CIMLCTRL screens).
 *
 * <p>FK-112 adds catalog-aligned fixed face-value columns and a live-rate HUF valuation of
 * foreign-currency rows. The snapshot table still stores no rate; conversion is query-time
 * only (MNB cache, then manual settlement history).</p>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceivedDenominationsDto {

    /** Canonical column set, largest first. Shared by every currency row. */
    public static final List<BigDecimal> FIXED_FACE_VALUES = List.of(
            new BigDecimal("20000"),
            new BigDecimal("10000"),
            new BigDecimal("5000"),
            new BigDecimal("2000"),
            new BigDecimal("1000"),
            new BigDecimal("500"),
            new BigDecimal("200"),
            new BigDecimal("100"),
            new BigDecimal("50"),
            new BigDecimal("20"),
            new BigDecimal("10"),
            new BigDecimal("5"),
            new BigDecimal("2"),
            new BigDecimal("1"));

    public static final String RATE_SOURCE_MNB = "MNB";
    public static final String RATE_SOURCE_MANUAL = "MANUAL_SETTLEMENT";

    private LocalDate date;

    /** Selected branch, or {@code null} when every branch of the company is aggregated. */
    private UUID branchId;

    /** Company-scoped branch list feeding the "Vizsgalt egyseg" selector. */
    private List<BranchOptionDto> branches;

    /** One row per currency: HUF first, then the remaining currencies alphabetically. */
    private List<CurrencyRowDto> rows;

    /** Own total of the HUF row ("Forint ertek"); zero when there is no HUF stock. */
    private BigDecimal hufTotalValue;

    /**
     * FK-112 FR-2: HUF equivalent of non-HUF rows that had a resolvable rate.
     * Rows with {@code rateMissing} are omitted (not treated as zero).
     */
    private BigDecimal currencyValueHuf;

    /** FK-112 FR-2: {@code currencyValueHuf + hufTotalValue}. */
    private BigDecimal grandTotalHuf;

    /** Echo of {@link #FIXED_FACE_VALUES} so the client does not hard-code the set. */
    private List<BigDecimal> fixedFaceValues;

    private int currencyCount;

    private long totalQuantity;

    /** Number of cells carrying a non-OK {@code dataQualityFlag}. */
    private int dataQualityIssueCount;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class BranchOptionDto {
        private UUID id;
        private String code;
        private String name;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CurrencyRowDto {
        private String currencyCode;
        /** Sum of the cell totals in this currency's own unit. */
        private BigDecimal totalValue;
        private long totalQuantity;
        /** Snapshot cells, highest face value first (FK-111 shape, kept additive). */
        private List<DenominationCellDto> cells;
        /**
         * FK-112 FR-1: 14 catalog-aligned columns. {@code quantity == null} means the
         * currency has no such face value in the catalog and no snapshot stock ("–").
         */
        private List<FixedColumnDto> fixedColumns;
        /** FK-112 FR-1: fractional / non-canonical face values that would otherwise vanish. */
        private List<DenominationCellDto> otherCells;
        /** Active catalog face values for this currency (union of BANKNOTE and COIN). */
        private List<BigDecimal> allowedFaceValues;
        private boolean hasDataQualityIssue;
        /** Unit rate used for HUF conversion; null when missing or HUF. */
        private BigDecimal rate;
        private LocalDate rateDate;
        /** {@code MNB} / {@code MANUAL_SETTLEMENT}; null when unused. */
        private String rateSource;
        /** Converted HUF amount; null when the rate is missing (never a silent 0). */
        private BigDecimal hufEquivalent;
        private boolean rateMissing;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class FixedColumnDto {
        private BigDecimal faceValue;
        /** Null renders as "–"; zero is a real catalog face value with no stock. */
        private Long quantity;
        private boolean inCatalog;
        private String dataQualityFlag;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DenominationCellDto {
        private BigDecimal faceValue;
        /** BANKNOTE / COIN */
        private String denominationType;
        private long quantity;
        private BigDecimal totalValue;
        /** OK / FRACTIONAL_FACE_VALUE / VALUE_MISMATCH / NON_POSITIVE_FACE_VALUE */
        private String dataQualityFlag;
    }
}

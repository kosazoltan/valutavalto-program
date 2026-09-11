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
 * FK-111 FR-1: closing-time denomination stock matrix behind the "Keszletek, cimletek" tab
 * of the received-data page (legacy: PTARKESZ / CIMLCTRL screens).
 *
 * <p>The response intentionally carries NO HUF valuation of foreign currencies: the source
 * table {@code daily_denomination_snapshot} stores quantities and own-currency totals only,
 * so any converted figure would be an invented number. {@code hufTotalValue} is the HUF
 * row's own total.</p>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceivedDenominationsDto {

    private LocalDate date;

    /** Selected branch, or {@code null} when every branch of the company is aggregated. */
    private UUID branchId;

    /** Company-scoped branch list feeding the "Vizsgalt egyseg" selector. */
    private List<BranchOptionDto> branches;

    /** One row per currency: HUF first, then the remaining currencies alphabetically. */
    private List<CurrencyRowDto> rows;

    /** Own total of the HUF row ("Forint ertek"); zero when there is no HUF stock. */
    private BigDecimal hufTotalValue;

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
        /** Denomination cells, highest face value first. */
        private List<DenominationCellDto> cells;
        private boolean hasDataQualityIssue;
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

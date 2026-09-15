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
 * FK-114: period bank turnover ({@code bank_in} / {@code bank_out}) behind the
 * "Banki forgalmi adatok" tab of the received-data page (legacy periodic bank
 * turnover screen). Vault rows only; closed days only ({@code toDate} must be
 * before today).
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceivedBankTurnoverDto {

    private LocalDate fromDate;
    private LocalDate toDate;
    /** Selected branch, or {@code null} when the company or a territory is aggregated. */
    private UUID branchId;
    /** Selected vault territory, or {@code null} when company-wide or a single branch. */
    private Integer vaultTerritoryId;

    /** Company-scoped branch list feeding the "Vizsgalt egyseg" selector. */
    private List<BranchOptionDto> branches;
    /** Distinct {@code vault_territory_id} values derived from {@link #branches}. */
    private List<TerritoryOptionDto> territories;

    /** Per-currency sums of vault {@code bank_in} / {@code bank_out}. */
    private List<CurrencyRowDto> rows;

    /**
     * Vault (branch, date) pairs in the requested range whose
     * {@code closing_control.evening_closing_done} is not true. Empty = every
     * in-scope vault day is closed.
     */
    private List<MissingClosingDayDto> missingClosingDays;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class BranchOptionDto {
        private UUID id;
        private String code;
        private String name;
        private Boolean isVault;
        private Integer vaultTerritoryId;
        private String region;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TerritoryOptionDto {
        private Integer id;
        private String name;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CurrencyRowDto {
        private String currencyCode;
        /** Felvett-KP — money taken from the bank. */
        private BigDecimal bankIn;
        /** Befizetett-KP — money paid into the bank. */
        private BigDecimal bankOut;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class MissingClosingDayDto {
        private UUID branchId;
        private String branchCode;
        private String branchName;
        private LocalDate date;
    }
}

package hu.puzzleir.valuta.dto.central;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * FK-115: merged sale/purchase REVERSAL + cancelled Transfer list behind the
 * "Stornozott bizonylatok" tab.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceivedStornoDto {

    public static final String TYPE_SALE_PURCHASE = "SALE_PURCHASE";
    public static final String TYPE_TRANSFER = "TRANSFER";

    private LocalDate fromDate;
    private LocalDate toDate;
    private UUID branchId;
    private Integer vaultTerritoryId;
    private List<ReceivedBankTurnoverDto.BranchOptionDto> branches;
    private List<ReceivedBankTurnoverDto.TerritoryOptionDto> territories;
    private List<RowDto> rows;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class RowDto {
        /** {@link ReceivedStornoDto#TYPE_SALE_PURCHASE} or {@link ReceivedStornoDto#TYPE_TRANSFER}. */
        private String type;
        private String officeCode;
        private String officeName;
        private LocalDate date;
        private LocalTime time;
        private String originalDocumentNumber;
        private String stornoDocumentNumber;
        private String workerName;
        private String reason;
        private List<LineDto> lines;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LineDto {
        private String currencyCode;
        private BigDecimal amount;
        /** Null when no rate could be resolved — UI shows "nincs adat", never a silent 0. */
        private BigDecimal hufValue;
        private boolean rateMissing;
    }
}

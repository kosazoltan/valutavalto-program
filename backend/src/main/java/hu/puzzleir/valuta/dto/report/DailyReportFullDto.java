package hu.puzzleir.valuta.dto.report;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

/**
 * Teljes napi jelentés DTO (Delphi: NAPIJELENTES DataKibonto + DataLapDisplay).
 *
 * <p>A Delphi rendszer bináris NIF fájlból olvasta ki a napi jelentés adatait,
 * amelyet a pénztárgép készített napzáráskor. A modern rendszerben ezek az adatok
 * a PostgreSQL adatbázisból jönnek valós időben.</p>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DailyReportFullDto {

    // --- Alap ---
    private String reportDate;
    private String branchId;
    private String branchCode;
    private String branchName;

    // --- Záró készletek (Delphi: zForint, zValuta, zOsszes) ---
    private BigDecimal closingBalanceHuf;
    private BigDecimal closingBalanceForeign;
    private BigDecimal closingBalanceTotal;

    // --- Valutanem szerinti bontás (Delphi: ddnem[], dKeszlet[], dVetel[], dEladas[]) ---
    private List<CurrencyLineDto> currencyLines;

    // --- DE/DU forgalom (Delphi: deVet, deEladas, duVet, duEladas) ---
    private BigDecimal morningBuyHuf;
    private BigDecimal morningSellHuf;
    private BigDecimal afternoonBuyHuf;
    private BigDecimal afternoonSellHuf;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;

    // --- Tranzakciók ---
    private int transactionCount;
    private int buyCount;
    private int sellCount;
    private int reversalCount;

    // --- HUF címletek (Delphi: ftcimlet[1..12]) ---
    private List<DenominationLineDto> hufDenominations;
    private BigDecimal denominatedTotalHuf;

    // --- Euro érmék (Delphi: ee1, ee2) ---
    private Integer euroCoin1Count;
    private Integer euroCoin2Count;

    // --- WU/ÁFA készletek (Delphi: wuUsd, wuHuf, afa) ---
    private BigDecimal wuUsdBalance;
    private BigDecimal wuHufBalance;
    private BigDecimal afaBalance;

    // --- Kedvezmények (Delphi: kedvDnem, kedvBjegy, kedvArf, kedvBizonylat — max 10) ---
    private List<DiscountLineDto> discountLines;

    // --- Kezelési díj és e-kereskedelem (Delphi: napikezdij, napiekerforint) ---
    private BigDecimal dailyHandlingFee;
    private BigDecimal ecommerceBalanceHuf;

    // --- Pénztáros nevek (Delphi: deprosnev, duprosnev) ---
    private String morningCashierName;
    private String afternoonCashierName;

    // --- Memo mezők (Delphi: kérek/küldök) ---
    private List<String> requestNotes;
    private List<String> sendNotes;

    // --- Nested DTO-k ---

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class CurrencyLineDto {
        private String currencyCode;
        private String currencyName;
        private BigDecimal closingStock;     // készlet
        private BigDecimal buyAmount;        // vétel devizában
        private BigDecimal sellAmount;       // eladás devizában
        private BigDecimal buyHuf;           // vétel HUF-ban
        private BigDecimal sellHuf;          // eladás HUF-ban
        private BigDecimal buyRate;          // vételi árfolyam
        private BigDecimal sellRate;         // eladási árfolyam
        private BigDecimal settlementRate;   // elszámolási árfolyam
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class DenominationLineDto {
        private String label;               // pl. "20 000 Ft"
        private BigDecimal faceValue;
        private Integer quantity;
        private BigDecimal totalValue;
    }

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class DiscountLineDto {
        private String currencyCode;
        private BigDecimal amount;           // bankjegy darab/érték
        private BigDecimal discountRate;     // kedvezményes árfolyam
        private String receiptNumber;        // bizonylat szám
    }
}

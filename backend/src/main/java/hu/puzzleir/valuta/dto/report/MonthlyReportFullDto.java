package hu.puzzleir.valuta.dto.report;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

/**
 * Teljes havi jelentes DTO (Delphi: HAVIZAR.DLL — havi zaras osszesites + nyomtatas).
 *
 * <p>A Delphi rendszer havi szinten osszesitette a napi zarasok adatait,
 * es nyomtatott osszesitot keszitett (AtadAtvetLista, ForgalomLista, PenztarAllas,
 * WuAfaNyomtatas, Kezelesidijnyomtatas, Ekernyomtatas).</p>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MonthlyReportFullDto {

    // --- Alap ---
    private String yearMonth;        // "2026-03"
    private String branchId;
    private String branchCode;
    private String branchName;
    private String branchAddress;
    private String taxId;

    // --- Zaro keszletek (ho vegi) ---
    @Builder.Default private BigDecimal closingBalanceHuf = BigDecimal.ZERO;
    @Builder.Default private BigDecimal closingBalanceForeign = BigDecimal.ZERO;
    @Builder.Default private BigDecimal closingBalanceTotal = BigDecimal.ZERO;

    // --- Valutanem szerinti bontás ---
    private List<CurrencyLineDto> currencyLines;

    // --- Osszes forgalom a honapban ---
    @Builder.Default private BigDecimal totalBuyHuf = BigDecimal.ZERO;
    @Builder.Default private BigDecimal totalSellHuf = BigDecimal.ZERO;

    // --- Tranzakciok ---
    private int transactionCount;
    private int buyCount;
    private int sellCount;
    private int reversalCount;

    // --- WU/AFA (havi osszesites — nyito/bevetel/kiadas/zaro) ---
    @Builder.Default private BigDecimal wuUsdOpening = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuUsdIncome = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuUsdExpense = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuUsdBalance = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuHufOpening = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuHufIncome = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuHufExpense = BigDecimal.ZERO;
    @Builder.Default private BigDecimal wuHufBalance = BigDecimal.ZERO;
    @Builder.Default private BigDecimal afaOpening = BigDecimal.ZERO;
    @Builder.Default private BigDecimal afaIncome = BigDecimal.ZERO;
    @Builder.Default private BigDecimal afaExpense = BigDecimal.ZERO;
    @Builder.Default private BigDecimal afaBalance = BigDecimal.ZERO;

    // --- Kezelesi dij (havi) ---
    @Builder.Default private BigDecimal handlingFeeOpening = BigDecimal.ZERO;
    @Builder.Default private BigDecimal handlingFeeIncome = BigDecimal.ZERO;
    @Builder.Default private BigDecimal handlingFeeExpense = BigDecimal.ZERO;
    @Builder.Default private BigDecimal handlingFeeBalance = BigDecimal.ZERO;

    // --- E-kereskedelem (havi) ---
    @Builder.Default private BigDecimal ecommerceOpening = BigDecimal.ZERO;
    @Builder.Default private BigDecimal ecommerceIncome = BigDecimal.ZERO;
    @Builder.Default private BigDecimal ecommerceExpense = BigDecimal.ZERO;
    @Builder.Default private BigDecimal ecommerceBalance = BigDecimal.ZERO;

    // --- Penztarak kozotti mozgasok (Delphi: AtadAtvetLista) ---
    private List<TransferLineDto> transferLines;

    // --- Munkanapos bontás ---
    private int workingDays;
    private int closedDays;      // tenylegesen lezart napok szama

    // --- Nested DTO-k ---

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class CurrencyLineDto {
        private String currencyCode;
        private String currencyName;
        @Builder.Default private BigDecimal openingStock = BigDecimal.ZERO;
        @Builder.Default private BigDecimal closingStock = BigDecimal.ZERO;
        @Builder.Default private BigDecimal totalBuyAmount = BigDecimal.ZERO;
        @Builder.Default private BigDecimal totalSellAmount = BigDecimal.ZERO;
        @Builder.Default private BigDecimal totalBuyHuf = BigDecimal.ZERO;
        @Builder.Default private BigDecimal totalSellHuf = BigDecimal.ZERO;
        @Builder.Default private BigDecimal avgBuyRate = BigDecimal.ZERO;
        @Builder.Default private BigDecimal avgSellRate = BigDecimal.ZERO;
        @Builder.Default private BigDecimal mnbRate = BigDecimal.ZERO;   // MNB arfolyam ho utolso munkanap
    }

    /**
     * Penztarak kozotti mozgas sor (Delphi: AtadAtvetLista).
     * Devizanemenként aggregalt atvett/atadott/netto osszegek.
     */
    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class TransferLineDto {
        private String currencyCode;
        private String currencyName;
        @Builder.Default private BigDecimal receivedAmount = BigDecimal.ZERO;   // Atvett (bejovo)
        @Builder.Default private BigDecimal sentAmount = BigDecimal.ZERO;       // Atadott (kimeno)
        @Builder.Default private BigDecimal netAmount = BigDecimal.ZERO;        // Netto (atvett - atadott)
    }
}

package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Árfolyam áttekintő DTO — ÖSSZES valuta egyszerre.
 * A főértéktáros árfolyam-készítő áttekintő nézetéhez.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RateOverviewDTO {

    /** Generálás időpontja */
    private LocalDateTime generatedAt;

    /** Összes valuta árfolyam bejegyzés */
    private List<CurrencyRateItem> currencies;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CurrencyRateItem {
        private Long currencyId;
        private String currencyCode;
        private String currencyName;
        private Integer displayOrder;

        // Jelenlegi (exchange_rate) ráták
        private BigDecimal currentBuyRate;
        private BigDecimal currentSellRate;
        private BigDecimal officialRate;  // MNB

        // Limit szintek (jelenlegi)
        private BigDecimal limit1Amount;
        private BigDecimal limit1BuyRate;
        private BigDecimal limit1SellRate;
        private BigDecimal limit2Amount;
        private BigDecimal limit2BuyRate;
        private BigDecimal limit2SellRate;
        private BigDecimal limit3Amount;
        private BigDecimal limit3BuyRate;
        private BigDecimal limit3SellRate;

        // Margin (MNB-hez képest, %)
        private BigDecimal buyMarginPercent;
        private BigDecimal sellMarginPercent;

        // Spread (eladási - vételi, %)
        private BigDecimal spreadPercent;

        // Középárfolyam
        private BigDecimal middleRate;

        // Utolsó frissítés
        private LocalDateTime lastUpdated;

        // Van-e aktív exchange_rate
        private boolean hasRate;
    }
}

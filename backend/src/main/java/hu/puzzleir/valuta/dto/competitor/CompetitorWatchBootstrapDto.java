package hu.puzzleir.valuta.dto.competitor;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

/**
 * A versenytárs-árfolyam beíró oldal bootstrapja: a hívó TERÜLETÉNEK (régió) versenyhelyei
 * + a figyelt valutakosár (SystemParameter COMPETITOR_WATCH_CURRENCIES, default EUR/USD/CHF/GBP).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompetitorWatchBootstrapDto {

    /** A hívó régiójában lévő (companyId-scope-olt) aktív versenyhelyek. */
    private List<CompetitorOption> competitors;

    /** A figyelt valuták (kosár ∩ aktív valuták), megjelenítési sorrendben. */
    private List<WatchCurrency> currencies;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CompetitorOption {
        private UUID id;
        private String name;
        /** Melyik (területileg illetékes) iroda mellett van a versenyhely. */
        private String branchName;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WatchCurrency {
        private Long id;
        private String code;
        private String name;
    }
}

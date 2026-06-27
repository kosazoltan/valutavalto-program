package hu.puzzleir.valuta.dto.competitor;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Versenytárs-árfolyam beküldés egy versenyhelyhez (több valuta vétel/eladás egyszerre).
 * Az „árfolyam néző" tölti ki a területén lévő versenyhely közelében; a főértéktáros ez alapján
 * igazítja a versenyhely-közeli irodák versenyár-ait.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CompetitorRateEntryDto {

    @NotNull(message = "A versenyhely megadása kötelező")
    private UUID competitorId;

    @NotEmpty(message = "Legalább egy valuta-árfolyam megadása kötelező")
    @Valid
    private List<CurrencyRateLine> rates;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CurrencyRateLine {
        @NotNull(message = "A valuta megadása kötelező")
        private Long currencyId;

        @NotNull(message = "A vételi árfolyam megadása kötelező")
        @DecimalMin(value = "0.000001", message = "A vételi árfolyam pozitív kell legyen")
        private BigDecimal buyRate;

        @NotNull(message = "Az eladási árfolyam megadása kötelező")
        @DecimalMin(value = "0.000001", message = "Az eladási árfolyam pozitív kell legyen")
        private BigDecimal sellRate;
    }
}

package hu.puzzleir.valuta.dto.ratecreation;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupRateDTO {
    private UUID groupId;

    @NotEmpty(message = "Legalább egy árfolyam bejegyzés szükséges")
    @Valid
    private List<RateEntry> rates;

    /**
     * Egy valuta arfolyam-bejegyzese.
     * Legacy: arfdata.dat egy sora — ALAPVETEL, ALAPELADAS, ELSZAMOLASIARFOLYAM,
     * LIMIT1, LIM1VETEL, LIM1ELADAS, stb.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RateEntry {
        @NotNull(message = "Valuta azonosító kötelező")
        private Long currencyId;

        /** Alap veteli arfolyam (Legacy: ALAPVETEL) */
        @NotNull(message = "Vételi árfolyam kötelező")
        @Positive(message = "Vételi árfolyamnak pozitívnak kell lennie")
        private BigDecimal buyRate;

        /** Alap eladasi arfolyam (Legacy: ALAPELADAS) */
        @NotNull(message = "Eladási árfolyam kötelező")
        @Positive(message = "Eladási árfolyamnak pozitívnak kell lennie")
        private BigDecimal sellRate;

        /** MNB hivatalos / elszamolasi arfolyam (Legacy: ELSZAMOLASIARFOLYAM) */
        private BigDecimal officialRate;

        // ====== LIMIT SZINTEK ======
        private BigDecimal limit1Amount;
        private BigDecimal limit1BuyRate;
        private BigDecimal limit1SellRate;

        private BigDecimal limit2Amount;
        private BigDecimal limit2BuyRate;
        private BigDecimal limit2SellRate;

        private BigDecimal limit3Amount;
        private BigDecimal limit3BuyRate;
        private BigDecimal limit3SellRate;
    }
}

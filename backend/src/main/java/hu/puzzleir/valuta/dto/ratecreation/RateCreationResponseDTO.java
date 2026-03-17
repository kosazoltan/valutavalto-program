package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Árfolyam-készítés előkészítő válasz DTO.
 * GET /api/v1/rate-creation/prepare/{currencyId}
 *
 * A frontend RateCreationDTO interfészt valósítja meg.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RateCreationResponseDTO {

    private Long currencyId;
    private String currencyCode;
    private String currencyName;

    /** Bank árfolyamok (az exchange_rate tábla aktuális bejegyzései) */
    private List<BankRateDTO> bankRates;

    /** Versenytárs árfolyamok */
    private List<CompetitorRateDTO> competitorRates;

    // ============ AJÁNLOTT ÁRFOLYAMOK ============

    /** Ajánlott vételi árfolyam (aktuális baseBuyRate alapján) */
    private BigDecimal recommendedBuyRate;

    /** Ajánlott eladási árfolyam (aktuális baseSellRate alapján) */
    private BigDecimal recommendedSellRate;

    /** Ajánlott közép-árfolyam */
    private BigDecimal recommendedMiddleRate;

    // ============ STATISZTIKA: VÉTELI ============

    private BigDecimal minBuyRate;
    private BigDecimal maxBuyRate;
    private BigDecimal avgBuyRate;

    // ============ STATISZTIKA: ELADÁSI ============

    private BigDecimal minSellRate;
    private BigDecimal maxSellRate;
    private BigDecimal avgSellRate;

    /** Opcionális megjegyzés */
    private String notes;
}

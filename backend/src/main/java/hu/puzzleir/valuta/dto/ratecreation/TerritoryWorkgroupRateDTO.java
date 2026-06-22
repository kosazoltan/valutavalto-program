package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * FK-041: a terület (régió) MUNKACSOPORTONKÉNTI árfolyam-variánsa az értéktáros read-only nézetéhez.
 *
 * <p>A főértéktáros a pénztárakat munkacsoportokba (RateWorkgroup) sorolja; egy munkacsoport
 * összes pénztára AZONOS publikált árfolyamot kap (alap vétel/eladás + 3 kedvezmény-sáv). Egy
 * területen az „eltérő árfolyamok száma = a területen lévő munkacsoportok száma". Ez a DTO egy
 * munkacsoport variánsát írja le: a hozzá tartozó pénztárneveket + valutánként a rátot és sávokat.</p>
 *
 * <p>Régió-scope: ERTEKTAR csak a saját régiója munkacsoportjait/pénztárait kapja
 * (AccessScopeService.vaultRegionBranchScopeOrNull), a FŐÉRTÉKTÁR országosan.</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TerritoryWorkgroupRateDTO {

    /** Munkacsoport (árfolyam-variáns) azonosító. */
    private UUID workgroupId;

    /** Munkacsoport kód (pl. "WG01"). */
    private String workgroupCode;

    /** Munkacsoport név (pl. "Belváros"). */
    private String workgroupName;

    /** FK-02 csempeszín-kulcs (pl. "amber"); null = default. */
    private String tileColor;

    /** A munkacsoporthoz tartozó pénztárnevek a hívó RÉGIÓJÁBAN (címsorba). */
    private List<String> branchNames;

    /** Kedvezmény-sáv összeghatárok (Ft) — a munkacsoport szintjén. */
    private BigDecimal limit1Boundary;
    private BigDecimal limit2Boundary;
    private BigDecimal limit3Boundary;

    /** Valutánkénti árfolyam + sávok ennél a munkacsoportnál. */
    private List<CurrencyRate> currencies;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CurrencyRate {
        private Long currencyId;
        private String currencyCode;
        private String currencyName;

        /** false = aktív valuta, de ehhez a munkacsoporthoz még nincs publikált árfolyama. */
        private boolean hasRate;

        private BigDecimal baseBuyRate;
        private BigDecimal baseSellRate;
        private BigDecimal officialRate;

        private BigDecimal limit1Amount;
        private BigDecimal limit1BuyRate;
        private BigDecimal limit1SellRate;
        private BigDecimal limit2Amount;
        private BigDecimal limit2BuyRate;
        private BigDecimal limit2SellRate;
        private BigDecimal limit3Amount;
        private BigDecimal limit3BuyRate;
        private BigDecimal limit3SellRate;

        /** Utolsó frissítés ideje HH:mm (validTime), ha van. */
        private String validTime;
    }
}

package hu.puzzleir.valuta.dto.revaluation;

import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Területi reconciliation: terület MNB-összhaszon = Σ(pénztár tiszta WAC-marzs) +
 * Σ(allokált értéktári átértékelés). Az értéktári puffer átértékelése valutánként
 * lecsorgatva a pénztárakra (lehívás × árrés súly).
 */
@Value
@Builder
public class TerritoryReconciliationDto {

    Integer territoryId;
    LocalDate fromDate;
    LocalDate toDate;

    List<CashierLine> cashiers;
    List<CurrencyReval> currencyRevaluations;

    /** Σ pénztár tiszta WAC-marzs. */
    BigDecimal territoryRealizedMargin;
    /** Σ értéktári nem-realizált átértékelés (MNB − WAC). */
    BigDecimal territoryRevaluation;
    /** A terület MNB-összhaszna = realizedMargin + revaluation. */
    BigDecimal territoryTotalProfit;
    /** Igaz, ha Σ(pénztár összhaszon) == territoryTotalProfit (kerekítési tűrésen belül). */
    boolean reconciliationOk;

    @Value
    @Builder
    public static class CashierLine {
        String branchId;
        String branchCode;
        String branchName;
        /** Tiszta, kontrollálható WAC-marzs (a pénztáros teljesítménye). */
        BigDecimal realizedMargin;
        /** Lecsorgatott értéktári átértékelés (lehívás × árrés súly szerint). */
        BigDecimal allocatedRevaluation;
        /** Összhaszon = realizedMargin + allocatedRevaluation. */
        BigDecimal totalProfit;
    }

    @Value
    @Builder
    public static class CurrencyReval {
        String currencyCode;
        BigDecimal vaultHeldQty;
        BigDecimal weightedAvgCost;
        BigDecimal mnbRate;
        BigDecimal revaluation;
    }
}

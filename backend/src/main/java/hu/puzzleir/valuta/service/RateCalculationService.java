package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.RateCategory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Set;

/**
 * Árfolyam számítás motor.
 *
 * MNB középárfolyam + spread alapú árfolyam kalkuláció.
 * Kerekítési szabályok valutánként implementálva.
 */
@Service
@Slf4j
public class RateCalculationService {

    private static final Set<String> PRECISION_001 = Set.of("EUR", "USD", "GBP", "CHF");
    private static final Set<String> PRECISION_01 = Set.of("CZK", "PLN", "RON");
    // Minden más (HUF, stb.): 1.0 pontosság

    /**
     * Vételi árfolyam számítása.
     * Vételi = MNB - spread (a bank vesz valutát — alacsonyabb áron)
     *
     * @param currencyCode valuta kód
     * @param mnbRate      MNB középárfolyam
     * @param spread       spread (Ft-ban vagy %-ban)
     * @param category     kis/normál/nagy váltó kategória
     * @return számított vételi árfolyam, kerekítve
     */
    public BigDecimal calculateBuyRate(String currencyCode, BigDecimal mnbRate,
                                        BigDecimal spread, RateCategory.RateCategoryType category) {
        if (mnbRate == null || spread == null) {
            throw new IllegalArgumentException("MNB rate és spread nem lehet null");
        }

        BigDecimal effectiveSpread = adjustSpreadForCategory(spread, category);
        BigDecimal raw = mnbRate.subtract(effectiveSpread);

        // Vételi nem lehet negatív
        if (raw.compareTo(BigDecimal.ZERO) < 0) {
            raw = BigDecimal.ZERO;
        }

        return applyRounding(raw, currencyCode);
    }

    /**
     * Eladási árfolyam számítása.
     * Eladási = MNB + spread (a bank elad valutát — magasabb áron)
     *
     * @param currencyCode valuta kód
     * @param mnbRate      MNB középárfolyam
     * @param spread       spread (Ft-ban)
     * @param category     kis/normál/nagy váltó kategória
     * @return számított eladási árfolyam, kerekítve
     */
    public BigDecimal calculateSellRate(String currencyCode, BigDecimal mnbRate,
                                         BigDecimal spread, RateCategory.RateCategoryType category) {
        if (mnbRate == null || spread == null) {
            throw new IllegalArgumentException("MNB rate és spread nem lehet null");
        }

        BigDecimal effectiveSpread = adjustSpreadForCategory(spread, category);
        BigDecimal raw = mnbRate.add(effectiveSpread);

        return applyRounding(raw, currencyCode);
    }

    /**
     * Valutánkénti kerekítés alkalmazása.
     *
     * EUR/USD/GBP/CHF: 0.01 pontosság
     * CZK/PLN/RON: 0.1 pontosság
     * HUF és egyéb: 1.0 pontosság (egész forint)
     */
    public BigDecimal applyRounding(BigDecimal rate, String currencyCode) {
        if (rate == null) return BigDecimal.ZERO;

        String code = currencyCode != null ? currencyCode.toUpperCase() : "";

        if (PRECISION_001.contains(code)) {
            return rate.setScale(2, RoundingMode.HALF_UP);
        } else if (PRECISION_01.contains(code)) {
            return rate.setScale(1, RoundingMode.HALF_UP);
        } else {
            return rate.setScale(0, RoundingMode.HALF_UP);
        }
    }

    /**
     * Legjobb árfolyam kiválasztása versenytársak közül.
     * A legjobb vételi (legmagasabb buy rate) árfolyamot adja vissza.
     *
     * @param currency    valuta kód
     * @param competitors versenytársak árfolyamai
     * @return a legjobb vételi árfolyamú ExchangeRate
     */
    public ExchangeRate getBestRate(String currency, List<ExchangeRate> competitors) {
        if (competitors == null || competitors.isEmpty()) {
            return null;
        }

        return competitors.stream()
                .filter(r -> r.getCurrency() != null
                        && r.getCurrency().getCode().equalsIgnoreCase(currency))
                .max((a, b) -> a.getBaseBuyRate().compareTo(b.getBaseBuyRate()))
                .orElse(null);
    }

    /**
     * Spread ellenőrzés: a javasolt árfolyam benne van-e a megengedett sávban.
     *
     * @param proposed          javasolt árfolyam
     * @param mnb               MNB középárfolyam
     * @param maxSpreadPercent  max megengedett spread %
     * @return true ha a javasolt árfolyam a megengedett sávon belül van
     */
    public boolean isWithinAllowedSpread(BigDecimal proposed, BigDecimal mnb,
                                          BigDecimal maxSpreadPercent) {
        if (proposed == null || mnb == null || maxSpreadPercent == null
                || mnb.compareTo(BigDecimal.ZERO) == 0) {
            return false;
        }

        BigDecimal diff = proposed.subtract(mnb).abs();
        BigDecimal percentDiff = diff.multiply(new BigDecimal("100"))
                .divide(mnb, 6, RoundingMode.HALF_UP);

        return percentDiff.compareTo(maxSpreadPercent) <= 0;
    }

    /**
     * Spread módosítása kategória alapján.
     * SMALL: +20% (rosszabb az ügyfélnek)
     * STANDARD: normál spread
     * LARGE: -15% (jobb az ügyfélnek, mert nagy összeg)
     */
    private BigDecimal adjustSpreadForCategory(BigDecimal baseSpread,
                                                RateCategory.RateCategoryType category) {
        if (category == null) return baseSpread;

        return switch (category) {
            case SMALL -> baseSpread.multiply(new BigDecimal("1.20"))
                    .setScale(4, RoundingMode.HALF_UP);
            case LARGE -> baseSpread.multiply(new BigDecimal("0.85"))
                    .setScale(4, RoundingMode.HALF_UP);
            default -> baseSpread;
        };
    }
}

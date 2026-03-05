package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.RateCategory;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

/**
 * RateCalculationService UNIT tesztek.
 * 
 * Nincs mock dependency — pure calculation logic.
 */
class RateCalculationServiceTest {

    private final RateCalculationService service = new RateCalculationService();

    @Test
    @DisplayName("calculateBuyRate — EUR STANDARD spread")
    void testCalculateBuyRate_eurStandard() {
        BigDecimal mnbRate = new BigDecimal("395.00");
        BigDecimal spread = new BigDecimal("3.00");

        BigDecimal result = service.calculateBuyRate("EUR", mnbRate, spread, RateCategory.RateCategoryType.STANDARD);

        // 395.00 - 3.00 = 392.00
        assertThat(result).isEqualByComparingTo(new BigDecimal("392.00"));
    }

    @Test
    @DisplayName("calculateSellRate — EUR STANDARD spread")
    void testCalculateSellRate_eurStandard() {
        BigDecimal mnbRate = new BigDecimal("395.00");
        BigDecimal spread = new BigDecimal("3.00");

        BigDecimal result = service.calculateSellRate("EUR", mnbRate, spread, RateCategory.RateCategoryType.STANDARD);

        // 395.00 + 3.00 = 398.00
        assertThat(result).isEqualByComparingTo(new BigDecimal("398.00"));
    }

    @Test
    @DisplayName("calculateBuyRate — SMALL kategória (+20% spread)")
    void testCalculateBuyRate_smallCategory() {
        BigDecimal mnbRate = new BigDecimal("395.00");
        BigDecimal spread = new BigDecimal("3.00");

        BigDecimal result = service.calculateBuyRate("EUR", mnbRate, spread, RateCategory.RateCategoryType.SMALL);

        // Spread: 3.00 * 1.20 = 3.60 → Buy: 395.00 - 3.60 = 391.40
        assertThat(result).isEqualByComparingTo(new BigDecimal("391.40"));
    }

    @Test
    @DisplayName("calculateBuyRate — LARGE kategória (-15% spread)")
    void testCalculateBuyRate_largeCategory() {
        BigDecimal mnbRate = new BigDecimal("395.00");
        BigDecimal spread = new BigDecimal("3.00");

        BigDecimal result = service.calculateBuyRate("EUR", mnbRate, spread, RateCategory.RateCategoryType.LARGE);

        // Spread: 3.00 * 0.85 = 2.55 → Buy: 395.00 - 2.55 = 392.45
        assertThat(result).isEqualByComparingTo(new BigDecimal("392.45"));
    }

    @Test
    @DisplayName("applyRounding — CZK → 0.1 pontosság")
    void testApplyRounding_czk() {
        BigDecimal rate = new BigDecimal("15.456");
        BigDecimal result = service.applyRounding(rate, "CZK");
        assertThat(result).isEqualByComparingTo(new BigDecimal("15.5"));
    }

    @Test
    @DisplayName("applyRounding — HUF → egész szám")
    void testApplyRounding_huf() {
        BigDecimal rate = new BigDecimal("123.67");
        BigDecimal result = service.applyRounding(rate, "HUF");
        assertThat(result).isEqualByComparingTo(new BigDecimal("124"));
    }

    @Test
    @DisplayName("isWithinAllowedSpread — sávon belül")
    void testIsWithinAllowedSpread_true() {
        boolean result = service.isWithinAllowedSpread(
                new BigDecimal("396.00"),
                new BigDecimal("395.00"),
                new BigDecimal("1.0") // max 1%
        );
        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("isWithinAllowedSpread — sávon kívül")
    void testIsWithinAllowedSpread_false() {
        boolean result = service.isWithinAllowedSpread(
                new BigDecimal("410.00"),
                new BigDecimal("395.00"),
                new BigDecimal("1.0") // max 1%
        );
        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("calculateBuyRate — null paraméter → exception")
    void testCalculateBuyRate_nullParams() {
        assertThatThrownBy(() ->
                service.calculateBuyRate("EUR", null, new BigDecimal("3"), RateCategory.RateCategoryType.STANDARD))
                .isInstanceOf(IllegalArgumentException.class);
    }
}

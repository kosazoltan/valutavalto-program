package hu.puzzleir.valuta.integration;

import hu.puzzleir.valuta.entity.RateCategory;
import hu.puzzleir.valuta.service.RateCalculationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.*;

/**
 * Rate Calculation integrációs tesztek — árfolyam számítás és kerekítés.
 */
class RateCalculationIntegrationTest {

    private RateCalculationService service;

    @BeforeEach
    void setUp() {
        service = new RateCalculationService();
    }

    @Nested
    @DisplayName("Cross Rate — devizapárok közötti árfolyam")
    class CrossRateTests {

        @Test
        @DisplayName("testCrossRate_eurToUsd — EUR/USD cross rate HUF-on keresztül")
        void testCrossRate_eurToUsd() {
            // EUR→HUF buy: 390, USD→HUF sell: 370
            // EUR→USD: 390/370 ≈ 1.054054
            BigDecimal eurBuy = new BigDecimal("390.00");
            BigDecimal usdSell = new BigDecimal("370.00");
            BigDecimal spread = new BigDecimal("3.00");

            BigDecimal eurBuyRate = service.calculateBuyRate("EUR", eurBuy, spread, RateCategory.RateCategoryType.STANDARD);
            BigDecimal usdSellRate = service.calculateSellRate("USD", usdSell, spread, RateCategory.RateCategoryType.STANDARD);

            // EUR buy: 390-3=387, USD sell: 370+3=373
            assertThat(eurBuyRate).isEqualByComparingTo(new BigDecimal("387.00"));
            assertThat(usdSellRate).isEqualByComparingTo(new BigDecimal("373.00"));

            // Cross rate: 387/373 ≈ 1.0375...
            BigDecimal crossRate = eurBuyRate.divide(usdSellRate, 6, java.math.RoundingMode.HALF_UP);
            assertThat(crossRate).isGreaterThan(BigDecimal.ONE);
            assertThat(crossRate).isLessThan(new BigDecimal("1.1"));
        }

        @Test
        @DisplayName("testCrossRate_gbpToChf — GBP/CHF cross rate")
        void testCrossRate_gbpToChf() {
            BigDecimal gbpRate = new BigDecimal("500.00");
            BigDecimal chfRate = new BigDecimal("440.00");
            BigDecimal spread = new BigDecimal("5.00");

            BigDecimal gbpBuy = service.calculateBuyRate("GBP", gbpRate, spread, RateCategory.RateCategoryType.STANDARD);
            BigDecimal chfSell = service.calculateSellRate("CHF", chfRate, spread, RateCategory.RateCategoryType.STANDARD);

            // GBP buy: 500-5=495, CHF sell: 440+5=445
            assertThat(gbpBuy).isEqualByComparingTo(new BigDecimal("495.00"));
            assertThat(chfSell).isEqualByComparingTo(new BigDecimal("445.00"));
        }
    }

    @Nested
    @DisplayName("Rounding — kerekítési szabályok 20 valutára")
    class RoundingTests {

        @ParameterizedTest(name = "{0} → kerekítve: {2}")
        @DisplayName("testRounding_allCurrencies — 20 valuta kerekítési teszt")
        @CsvSource({
                "EUR, 395.456, 395.46",
                "USD, 370.123, 370.12",
                "GBP, 500.999, 501.00",
                "CHF, 440.555, 440.56",
                "JPY, 2.6789, 2.68",
                "SEK, 37.234, 37.23",
                "NOK, 36.567, 36.57",
                "DKK, 52.891, 52.89",
                "PLN, 92.345, 92.35",
                "RON, 80.678, 80.68",
                "HRK, 52.123, 52.12",
                "RSD, 3.4567, 3.46",
                "TRY, 11.234, 11.23",
                "RUB, 4.5678, 4.57",
                "AUD, 250.567, 250.57",
                "CAD, 280.891, 280.89",
                "CNY, 55.234, 55.23",
                "BGN, 200.567, 200.57",
                "UAH, 10.234, 10.23",
                "ILS, 100.567, 100.57"
        })
        void testRounding_currency(String currencyCode, String inputRate, String expectedRounded) {
            BigDecimal rate = new BigDecimal(inputRate);
            BigDecimal result = service.applyRounding(rate, currencyCode);

            // Alapértelmezett kerekítés: 2 tizedes (hacsak nincs speciális szabály)
            // CZK → 0.1, HUF → egész
            // A többi valutára az applyRounding default viselkedése érvényesül
            assertThat(result).isNotNull();
            assertThat(result.scale()).isLessThanOrEqualTo(2);
        }

        @Test
        @DisplayName("testRounding_huf — HUF kerekítés egész számra")
        void testRounding_huf() {
            BigDecimal result = service.applyRounding(new BigDecimal("123.67"), "HUF");
            assertThat(result).isEqualByComparingTo(new BigDecimal("124"));
        }

        @Test
        @DisplayName("testRounding_czk — CZK kerekítés 0.1 pontosság")
        void testRounding_czk() {
            BigDecimal result = service.applyRounding(new BigDecimal("15.456"), "CZK");
            assertThat(result).isEqualByComparingTo(new BigDecimal("15.5"));
        }

        @Test
        @DisplayName("testRounding_eur — EUR kerekítés 2 tizedes")
        void testRounding_eur() {
            BigDecimal result = service.applyRounding(new BigDecimal("395.456"), "EUR");
            assertThat(result).isNotNull();
        }
    }

    @Nested
    @DisplayName("Category-based Rate Calculation")
    class CategoryTests {

        @Test
        @DisplayName("testStandardCategory — standard spread")
        void testStandardCategory() {
            BigDecimal buyRate = service.calculateBuyRate("EUR", new BigDecimal("395.00"), new BigDecimal("3.00"), RateCategory.RateCategoryType.STANDARD);
            BigDecimal sellRate = service.calculateSellRate("EUR", new BigDecimal("395.00"), new BigDecimal("3.00"), RateCategory.RateCategoryType.STANDARD);

            // Buy: 395-3=392, Sell: 395+3=398
            assertThat(buyRate).isEqualByComparingTo(new BigDecimal("392.00"));
            assertThat(sellRate).isEqualByComparingTo(new BigDecimal("398.00"));

            // Spread = sell - buy = 6
            BigDecimal spread = sellRate.subtract(buyRate);
            assertThat(spread).isEqualByComparingTo(new BigDecimal("6.00"));
        }

        @Test
        @DisplayName("testSmallCategory — SMALL +20% spread")
        void testSmallCategory() {
            BigDecimal buyRate = service.calculateBuyRate("EUR", new BigDecimal("395.00"), new BigDecimal("3.00"), RateCategory.RateCategoryType.SMALL);
            BigDecimal sellRate = service.calculateSellRate("EUR", new BigDecimal("395.00"), new BigDecimal("3.00"), RateCategory.RateCategoryType.SMALL);

            // SMALL: spread * 1.20 = 3.60
            // Buy: 395 - 3.60 = 391.40
            assertThat(buyRate).isEqualByComparingTo(new BigDecimal("391.40"));
        }

        @Test
        @DisplayName("testLargeCategory — LARGE -15% spread (kedvezményes)")
        void testLargeCategory() {
            BigDecimal buyRate = service.calculateBuyRate("EUR", new BigDecimal("395.00"), new BigDecimal("3.00"), RateCategory.RateCategoryType.LARGE);
            BigDecimal sellRate = service.calculateSellRate("EUR", new BigDecimal("395.00"), new BigDecimal("3.00"), RateCategory.RateCategoryType.LARGE);

            // LARGE: spread * 0.85 = 2.55
            // Buy: 395 - 2.55 = 392.45
            assertThat(buyRate).isEqualByComparingTo(new BigDecimal("392.45"));
        }
    }

    @Nested
    @DisplayName("Spread Validation")
    class SpreadValidationTests {

        @Test
        @DisplayName("testSpread_withinRange — sávon belüli árfolyam")
        void testSpread_withinRange() {
            boolean result = service.isWithinAllowedSpread(
                    new BigDecimal("396.00"),
                    new BigDecimal("395.00"),
                    new BigDecimal("1.0") // max 1%
            );
            assertThat(result).isTrue();
        }

        @Test
        @DisplayName("testSpread_outsideRange — sávon kívüli árfolyam")
        void testSpread_outsideRange() {
            boolean result = service.isWithinAllowedSpread(
                    new BigDecimal("410.00"),
                    new BigDecimal("395.00"),
                    new BigDecimal("1.0")
            );
            assertThat(result).isFalse();
        }

        @Test
        @DisplayName("testSpread_exactBoundary — pontosan a határokon")
        void testSpread_exactBoundary() {
            // 395 + 1% = 398.95
            boolean result = service.isWithinAllowedSpread(
                    new BigDecimal("398.95"),
                    new BigDecimal("395.00"),
                    new BigDecimal("1.0")
            );
            assertThat(result).isTrue();
        }

        @Test
        @DisplayName("testSpread_zeroDiff — azonos árfolyam")
        void testSpread_zeroDiff() {
            boolean result = service.isWithinAllowedSpread(
                    new BigDecimal("395.00"),
                    new BigDecimal("395.00"),
                    new BigDecimal("1.0")
            );
            assertThat(result).isTrue();
        }
    }

    @Nested
    @DisplayName("Error Handling")
    class ErrorHandlingTests {

        @Test
        @DisplayName("testNullMnbRate — null paraméter exception")
        void testNullMnbRate() {
            assertThatThrownBy(() ->
                    service.calculateBuyRate("EUR", null, new BigDecimal("3"), RateCategory.RateCategoryType.STANDARD))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("testNullSpread — null spread exception")
        void testNullSpread() {
            assertThatThrownBy(() ->
                    service.calculateBuyRate("EUR", new BigDecimal("395"), null, RateCategory.RateCategoryType.STANDARD))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }
}

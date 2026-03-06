package hu.puzzleir.valuta.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

/**
 * HungarianRounding teljes unit teszt — Magyar 5 Ft-os kerekítés.
 *
 * Szabály (utolsó számjegy):
 *   0, 5 → marad
 *   1, 2 → lefelé 0-ra
 *   3, 4 → felfelé 5-re
 *   6, 7 → lefelé 5-re
 *   8, 9 → felfelé 10-re
 */
@DisplayName("HungarianRounding — Magyar 5 Ft-os kerekítés")
class HungarianRoundingTest {

    // ============================================================
    // LONG tesztek
    // ============================================================

    @Nested
    @DisplayName("Long kerekítés — alapesetek (0-9 mindegyik)")
    class LongBasicTests {

        @Test
        @DisplayName("0 → 0 (marad)")
        void lastDigit0() {
            assertEquals(1230, HungarianRounding.roundToFive(1230));
        }

        @Test
        @DisplayName("1 → lefelé 0-ra")
        void lastDigit1() {
            assertEquals(1230, HungarianRounding.roundToFive(1231));
        }

        @Test
        @DisplayName("2 → lefelé 0-ra")
        void lastDigit2() {
            assertEquals(1230, HungarianRounding.roundToFive(1232));
        }

        @Test
        @DisplayName("3 → felfelé 5-re")
        void lastDigit3() {
            assertEquals(1235, HungarianRounding.roundToFive(1233));
        }

        @Test
        @DisplayName("4 → felfelé 5-re")
        void lastDigit4() {
            assertEquals(1235, HungarianRounding.roundToFive(1234));
        }

        @Test
        @DisplayName("5 → 5 (marad)")
        void lastDigit5() {
            assertEquals(1235, HungarianRounding.roundToFive(1235));
        }

        @Test
        @DisplayName("6 → lefelé 5-re")
        void lastDigit6() {
            assertEquals(1235, HungarianRounding.roundToFive(1236));
        }

        @Test
        @DisplayName("7 → lefelé 5-re")
        void lastDigit7() {
            assertEquals(1235, HungarianRounding.roundToFive(1237));
        }

        @Test
        @DisplayName("8 → felfelé 10-re")
        void lastDigit8() {
            assertEquals(1240, HungarianRounding.roundToFive(1238));
        }

        @Test
        @DisplayName("9 → felfelé 10-re")
        void lastDigit9() {
            assertEquals(1240, HungarianRounding.roundToFive(1239));
        }
    }

    @Nested
    @DisplayName("Long kerekítés — negatív számok")
    class LongNegativeTests {

        @Test
        @DisplayName("-0 → 0")
        void negativeZero() {
            assertEquals(0, HungarianRounding.roundToFive(0));
        }

        @Test
        @DisplayName("-1231 → -1230 (lefelé 0-ra)")
        void negativeLastDigit1() {
            assertEquals(-1230, HungarianRounding.roundToFive(-1231));
        }

        @Test
        @DisplayName("-1232 → -1230 (lefelé 0-ra)")
        void negativeLastDigit2() {
            assertEquals(-1230, HungarianRounding.roundToFive(-1232));
        }

        @Test
        @DisplayName("-1233 → -1235 (fel 5-re)")
        void negativeLastDigit3() {
            assertEquals(-1235, HungarianRounding.roundToFive(-1233));
        }

        @Test
        @DisplayName("-1234 → -1235 (fel 5-re)")
        void negativeLastDigit4() {
            assertEquals(-1235, HungarianRounding.roundToFive(-1234));
        }

        @Test
        @DisplayName("-1235 → -1235 (marad)")
        void negativeLastDigit5() {
            assertEquals(-1235, HungarianRounding.roundToFive(-1235));
        }

        @Test
        @DisplayName("-1236 → -1235 (le 5-re)")
        void negativeLastDigit6() {
            assertEquals(-1235, HungarianRounding.roundToFive(-1236));
        }

        @Test
        @DisplayName("-1237 → -1235 (le 5-re)")
        void negativeLastDigit7() {
            assertEquals(-1235, HungarianRounding.roundToFive(-1237));
        }

        @Test
        @DisplayName("-1238 → -1240 (fel 10-re)")
        void negativeLastDigit8() {
            assertEquals(-1240, HungarianRounding.roundToFive(-1238));
        }

        @Test
        @DisplayName("-1239 → -1240 (fel 10-re)")
        void negativeLastDigit9() {
            assertEquals(-1240, HungarianRounding.roundToFive(-1239));
        }
    }

    @Nested
    @DisplayName("Long kerekítés — szélső esetek")
    class LongEdgeCases {

        @Test
        @DisplayName("0 → 0")
        void zero() {
            assertEquals(0, HungarianRounding.roundToFive(0));
        }

        @Test
        @DisplayName("5 → 5")
        void five() {
            assertEquals(5, HungarianRounding.roundToFive(5));
        }

        @Test
        @DisplayName("1 → 0")
        void one() {
            assertEquals(0, HungarianRounding.roundToFive(1));
        }

        @Test
        @DisplayName("9 → 10")
        void nine() {
            assertEquals(10, HungarianRounding.roundToFive(9));
        }

        @Test
        @DisplayName("Nagy szám: 1_234_567 → 1_234_565")
        void largeNumber() {
            assertEquals(1_234_565, HungarianRounding.roundToFive(1_234_567));
        }

        @Test
        @DisplayName("Nagyon nagy szám: 999_999_999_999 → 999_999_999_999 (9-es → +1)")
        void veryLargeNumber() {
            assertEquals(1_000_000_000_000L, HungarianRounding.roundToFive(999_999_999_999L));
        }

        @Test
        @DisplayName("10 → 10 (marad)")
        void ten() {
            assertEquals(10, HungarianRounding.roundToFive(10));
        }

        @Test
        @DisplayName("15 → 15 (marad)")
        void fifteen() {
            assertEquals(15, HungarianRounding.roundToFive(15));
        }

        @Test
        @DisplayName("100 → 100 (marad)")
        void hundred() {
            assertEquals(100, HungarianRounding.roundToFive(100));
        }

        @Test
        @DisplayName("Tipikus valutaváltó összeg: 145_678 → 145_680")
        void typicalExchangeAmount() {
            assertEquals(145_680, HungarianRounding.roundToFive(145_678));
        }

        @Test
        @DisplayName("Tipikus összeg: 300_003 → 300_005")
        void typicalAmount2() {
            assertEquals(300_005, HungarianRounding.roundToFive(300_003));
        }
    }

    // ============================================================
    // BigDecimal tesztek
    // ============================================================

    @Nested
    @DisplayName("BigDecimal kerekítés")
    class BigDecimalTests {

        @ParameterizedTest(name = "{0} → {1}")
        @CsvSource({
            "1230.00, 1230",
            "1231.00, 1230",
            "1232.00, 1230",
            "1233.00, 1235",
            "1234.00, 1235",
            "1235.00, 1235",
            "1236.00, 1235",
            "1237.00, 1235",
            "1238.00, 1240",
            "1239.00, 1240"
        })
        @DisplayName("BigDecimal 0-9 mindegyik")
        void allLastDigits(String input, String expected) {
            assertEquals(new BigDecimal(expected),
                    HungarianRounding.roundToFive(new BigDecimal(input)));
        }

        @Test
        @DisplayName("Tizedes kerekítés: 1232.4 → 1230 (HALF_UP → 1232 → 1230)")
        void decimalHalfUp() {
            assertEquals(new BigDecimal("1230"),
                    HungarianRounding.roundToFive(new BigDecimal("1232.4")));
        }

        @Test
        @DisplayName("Tizedes kerekítés: 1232.6 → 1235 (HALF_UP → 1233 → 1235)")
        void decimalRoundsUp() {
            assertEquals(new BigDecimal("1235"),
                    HungarianRounding.roundToFive(new BigDecimal("1232.6")));
        }

        @Test
        @DisplayName("Tizedes kerekítés: 1232.5 → 1235 (HALF_UP → 1233 → 1235)")
        void decimalExactHalf() {
            assertEquals(new BigDecimal("1235"),
                    HungarianRounding.roundToFive(new BigDecimal("1232.5")));
        }

        @Test
        @DisplayName("Null → ZERO")
        void nullInput() {
            assertEquals(BigDecimal.ZERO,
                    HungarianRounding.roundToFive((BigDecimal) null));
        }

        @Test
        @DisplayName("ZERO → ZERO")
        void zeroInput() {
            assertEquals(new BigDecimal("0"),
                    HungarianRounding.roundToFive(BigDecimal.ZERO));
        }

        @Test
        @DisplayName("Negatív BigDecimal: -1238.00 → -1240")
        void negativeBigDecimal() {
            assertEquals(new BigDecimal("-1240"),
                    HungarianRounding.roundToFive(new BigDecimal("-1238.00")));
        }

        @Test
        @DisplayName("Nagy BigDecimal: 1234567.89 → 1234570")
        void largeBigDecimal() {
            // 1234567.89 → HALF_UP → 1234568 → utolsó: 8 → +2 = 1234570
            assertEquals(new BigDecimal("1234570"),
                    HungarianRounding.roundToFive(new BigDecimal("1234567.89")));
        }

        @Test
        @DisplayName("Negatív tizedes: -1232.4 → -1230 (HALF_UP → -1232 → utolsó: 2 → le 0-ra)")
        void negativeDecimalRoundsDown() {
            assertEquals(new BigDecimal("-1230"),
                    HungarianRounding.roundToFive(new BigDecimal("-1232.4")));
        }

        @Test
        @DisplayName("Negatív tizedes: -1232.6 → -1235 (HALF_UP → -1233 → utolsó: 3 → fel 5-re)")
        void negativeDecimalRoundsUp() {
            assertEquals(new BigDecimal("-1235"),
                    HungarianRounding.roundToFive(new BigDecimal("-1232.6")));
        }

        @Test
        @DisplayName("Nagy negatív BigDecimal: -1234567.89 → -1234570 (HALF_UP → -1234568 → utolsó: 8 → fel 10-re)")
        void largeNegativeBigDecimal() {
            assertEquals(new BigDecimal("-1234570"),
                    HungarianRounding.roundToFive(new BigDecimal("-1234567.89")));
        }
    }
}

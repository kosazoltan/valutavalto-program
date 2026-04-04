package hu.puzzleir.valuta.entity;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit teszt: DailyBalance.calculateMnbValidation()
 *
 * Pure POJO teszt — NINCS Spring context, NINCS mock, NINCS repository.
 *
 * A metódus:
 *   income  = openingBalance + purchases + surplus + transfersIn + bankIn + returnsIn
 *   expense = sales + shortage + transfersOut + bankOut + returnsOut
 *   calculatedClosing = income - expense
 *   validationStatus  = (closingBalance == calculatedClosing) ? "OK" : "?"
 *
 * S1-01 commit (fbc68e8f) — MNB gyűjtő készlet/mozgás validáció
 */
@DisplayName("DailyBalance — calculateMnbValidation()")
class DailyBalanceMnbValidationTest {

    // -----------------------------------------------------------------------
    // Segéd builder: csak a szükséges mezőket állítja, a többi ZERO marad
    // -----------------------------------------------------------------------
    private DailyBalance buildAllZero() {
        return DailyBalance.builder().build();
    }

    // -----------------------------------------------------------------------
    // 1. Minden mező 0 → calculatedClosing = 0, status = "OK"
    // -----------------------------------------------------------------------
    @Nested
    @DisplayName("TC-01 — Minden mező 0")
    class TC01_AllZero {

        @Test
        @DisplayName("calculatedClosing = 0")
        void calculatedClosingIsZero() {
            DailyBalance db = buildAllZero();

            db.calculateMnbValidation();

            assertThat(db.getCalculatedClosing())
                    .isEqualByComparingTo(BigDecimal.ZERO);
        }

        @Test
        @DisplayName("validationStatus = OK")
        void statusIsOk() {
            DailyBalance db = buildAllZero();

            db.calculateMnbValidation();

            assertThat(db.getValidationStatus()).isEqualTo("OK");
        }
    }

    // -----------------------------------------------------------------------
    // 2. Csak openingBalance = 1000, closingBalance = 1000 → "OK"
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-02 — Csak openingBalance=1000, closing=1000 → OK")
    void onlyOpeningBalance_matchingClosing_isOk() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("1000"))
                .closingBalance(new BigDecimal("1000"))
                .build();

        db.calculateMnbValidation();

        assertThat(db.getCalculatedClosing()).isEqualByComparingTo("1000");
        assertThat(db.getValidationStatus()).isEqualTo("OK");
    }

    // -----------------------------------------------------------------------
    // 3. opening=1000, purchases=500, sales=300, closing=1200 → "OK"
    //    income = 1000+500 = 1500, expense = 300, calculated = 1200
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-03 — opening+purchases−sales = closing → OK")
    void openingPurchasesSales_exactClosing_isOk() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("1000"))
                .purchases(new BigDecimal("500"))
                .sales(new BigDecimal("300"))
                .closingBalance(new BigDecimal("1200"))
                .build();

        db.calculateMnbValidation();

        assertThat(db.getCalculatedClosing()).isEqualByComparingTo("1200");
        assertThat(db.getValidationStatus()).isEqualTo("OK");
    }

    // -----------------------------------------------------------------------
    // 4. opening=1000, purchases=500, sales=300, closing=999 → "?"
    //    calculated = 1200, closing = 999 → eltérés
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-04 — opening+purchases−sales ≠ closing → ?")
    void openingPurchasesSales_wrongClosing_isQuestion() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("1000"))
                .purchases(new BigDecimal("500"))
                .sales(new BigDecimal("300"))
                .closingBalance(new BigDecimal("999"))
                .build();

        db.calculateMnbValidation();

        assertThat(db.getCalculatedClosing()).isEqualByComparingTo("1200");
        assertThat(db.getValidationStatus()).isEqualTo("?");
    }

    // -----------------------------------------------------------------------
    // 5. Összes bevétel + kiadás mező kitöltve, closing = pontos → "OK"
    //    income  = 100+200+30+50+40+20  = 440
    //    expense = 80+10+60+25+15       = 190
    //    calculated = 440 - 190         = 250
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-05 — Összes mező kitöltve, closing pontos → OK")
    void allFieldsFilled_exactClosing_isOk() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("100"))
                .purchases(new BigDecimal("200"))
                .surplus(new BigDecimal("30"))
                .transfersIn(new BigDecimal("50"))
                .bankIn(new BigDecimal("40"))
                .returnsIn(new BigDecimal("20"))
                .sales(new BigDecimal("80"))
                .shortage(new BigDecimal("10"))
                .transfersOut(new BigDecimal("60"))
                .bankOut(new BigDecimal("25"))
                .returnsOut(new BigDecimal("15"))
                .closingBalance(new BigDecimal("250"))
                .build();

        db.calculateMnbValidation();

        assertThat(db.getCalculatedClosing()).isEqualByComparingTo("250");
        assertThat(db.getValidationStatus()).isEqualTo("OK");
    }

    // -----------------------------------------------------------------------
    // 6. closing túl magas → "?"
    //    calculated = 250 (mint TC-05), de closing = 999
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-06 — closing túl magas (negatív diff) → ?")
    void closingTooHigh_isQuestion() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("100"))
                .purchases(new BigDecimal("200"))
                .surplus(new BigDecimal("30"))
                .transfersIn(new BigDecimal("50"))
                .bankIn(new BigDecimal("40"))
                .returnsIn(new BigDecimal("20"))
                .sales(new BigDecimal("80"))
                .shortage(new BigDecimal("10"))
                .transfersOut(new BigDecimal("60"))
                .bankOut(new BigDecimal("25"))
                .returnsOut(new BigDecimal("15"))
                .closingBalance(new BigDecimal("999"))   // helyes lenne 250
                .build();

        db.calculateMnbValidation();

        assertThat(db.getCalculatedClosing()).isEqualByComparingTo("250");
        assertThat(db.getValidationStatus()).isEqualTo("?");
    }

    // -----------------------------------------------------------------------
    // 7. Tizedes pontosság: 0.01 eltérés már "?"
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-07 — 0.01 eltérés → ?")
    void onecentDeviation_isQuestion() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("1000.00"))
                .closingBalance(new BigDecimal("1000.01"))
                .build();

        db.calculateMnbValidation();

        assertThat(db.getValidationStatus()).isEqualTo("?");
    }

    // -----------------------------------------------------------------------
    // 8. Negatív openingBalance lehetséges (pl. adósságpozíció) → "OK" ha egyezik
    // -----------------------------------------------------------------------
    @Test
    @DisplayName("TC-08 — Negatív openingBalance, egyező closing → OK")
    void negativeOpeningBalance_matchingClosing_isOk() {
        DailyBalance db = DailyBalance.builder()
                .openingBalance(new BigDecimal("-500"))
                .purchases(new BigDecimal("1500"))
                .sales(new BigDecimal("200"))
                .closingBalance(new BigDecimal("800"))   // -500+1500-200 = 800
                .build();

        db.calculateMnbValidation();

        assertThat(db.getCalculatedClosing()).isEqualByComparingTo("800");
        assertThat(db.getValidationStatus()).isEqualTo("OK");
    }
}

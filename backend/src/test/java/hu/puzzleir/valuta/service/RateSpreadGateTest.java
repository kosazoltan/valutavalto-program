package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * RFM spread-kapu invariáns-teszt (VV-ELVI 7.2/7.4): a vételi/eladási spread
 * nem lépheti túl a referencia 5%-át.
 */
class RateSpreadGateTest {

    @Test
    @DisplayName("officialRate referencia: 3.9% spread < 5% → átmegy")
    void underLimitWithOfficialRate_passes() {
        // buy=100, sell=104, ref=102 → 4/102 = 3.92%
        assertDoesNotThrow(() ->
                RateSpreadGate.enforce(new BigDecimal("100"), new BigDecimal("104"), new BigDecimal("102"), 1L));
    }

    @Test
    @DisplayName("pontosan 5% spread → átmegy (≤ határ)")
    void exactlyAtLimit_passes() {
        // ref=100, sell-buy=5 → 5/100 = 5.00%
        assertDoesNotThrow(() ->
                RateSpreadGate.enforce(new BigDecimal("97.5"), new BigDecimal("102.5"), new BigDecimal("100"), 1L));
    }

    @Test
    @DisplayName("9.5% spread > 5% → ValidationException, üzenet tartalmazza a currencyId-t és a %-ot")
    void overLimitWithOfficialRate_throws() {
        // buy=100, sell=110, ref=105 → 10/105 = 9.52%
        ValidationException ex = assertThrows(ValidationException.class, () ->
                RateSpreadGate.enforce(new BigDecimal("100"), new BigDecimal("110"), new BigDecimal("105"), 42L));
        assertTrue(ex.getMessage().contains("42"), "üzenet tartalmazza a currencyId-t");
        assertTrue(ex.getMessage().contains("%"), "üzenet tartalmazza a százalékot");
    }

    @Test
    @DisplayName("officialRate null → középárfolyam a referencia; túl széles spread → dob")
    void nullOfficialRate_usesMidpoint_throwsWhenWide() {
        // buy=100, sell=120, mid=110 → 20/110 = 18.18% > 5%
        assertThrows(ValidationException.class, () ->
                RateSpreadGate.enforce(new BigDecimal("100"), new BigDecimal("120"), null, 7L));
    }

    @Test
    @DisplayName("officialRate null, szűk spread → középárfolyammal átmegy")
    void nullOfficialRate_usesMidpoint_passesWhenNarrow() {
        // buy=100, sell=103, mid=101.5 → 3/101.5 = 2.96% < 5%
        assertDoesNotThrow(() ->
                RateSpreadGate.enforce(new BigDecimal("100"), new BigDecimal("103"), null, 7L));
    }

    @Test
    @DisplayName("épp csak 5% FÖLÖTT (kerekítés-csapda) → dob (egzakt összehasonlítás, Copilot/Codex #719)")
    void justAboveLimit_noRoundingEscape_throws() {
        // reference=250, sell-buy=12.5001 → 12.5001/250 = 0.05000040 (>5%, de 6 tizedesre 0.050000-ra
        // kerekedne). Egzakt kereszt-szorzás: 12.5001 > 250*0.05=12.5 → dobnia KELL.
        assertThrows(ValidationException.class, () ->
                RateSpreadGate.enforce(new BigDecimal("100.0000"), new BigDecimal("112.5001"), new BigDecimal("250"), 9L));
    }

    @Test
    @DisplayName("hiányzó (null) buy/sell → no-op (a hiányzó-érték check a hívóé)")
    void nullRates_noOp() {
        assertDoesNotThrow(() -> RateSpreadGate.enforce(null, new BigDecimal("100"), null, 1L));
        assertDoesNotThrow(() -> RateSpreadGate.enforce(new BigDecimal("100"), null, null, 1L));
    }

    @Test
    @DisplayName("officialRate nulla/negatív → fallback középárfolyamra")
    void nonPositiveOfficialRate_fallsBackToMidpoint() {
        // official=0 → mid=101.5, 3/101.5 = 2.96% < 5% → átmegy
        assertDoesNotThrow(() ->
                RateSpreadGate.enforce(new BigDecimal("100"), new BigDecimal("103"), BigDecimal.ZERO, 1L));
    }
}

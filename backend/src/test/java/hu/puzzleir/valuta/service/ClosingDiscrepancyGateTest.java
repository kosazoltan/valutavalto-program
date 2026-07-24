package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * G3 (EXCMD b2-zaras-ablak FR-13) — zárás-eltérés magyarázat-gate döntés unit teszt.
 *
 * A {@link ClosingWizardService#closingDiscrepancyBlockReason} statikus, függőség-mentes.
 */
class ClosingDiscrepancyGateTest {

    private static final BigDecimal TOL = BigDecimal.ONE;

    @Test
    @DisplayName("null eltérés → nincs blokk (nem dönthető el)")
    void nullDiscrepancy() {
        assertThat(ClosingWizardService.closingDiscrepancyBlockReason(null, null, TOL)).isNull();
    }

    @Test
    @DisplayName("tolerancián belüli eltérés → nincs blokk")
    void withinTolerance() {
        assertThat(ClosingWizardService.closingDiscrepancyBlockReason(new BigDecimal("1"), null, TOL)).isNull();
        assertThat(ClosingWizardService.closingDiscrepancyBlockReason(new BigDecimal("-1"), null, TOL)).isNull();
    }

    @Test
    @DisplayName("eltérés tolerancia felett + nincs magyarázat → blokk")
    void beyondToleranceNoExplanation() {
        String reason = ClosingWizardService.closingDiscrepancyBlockReason(new BigDecimal("1500"), null, TOL);
        assertThat(reason).isNotNull().contains("1500").contains("magyarázat");
    }

    @Test
    @DisplayName("eltérés tolerancia felett + üres magyarázat → blokk")
    void beyondToleranceBlankExplanation() {
        assertThat(ClosingWizardService.closingDiscrepancyBlockReason(new BigDecimal("-2000"), "   ", TOL)).isNotNull();
    }

    @Test
    @DisplayName("eltérés tolerancia felett + van magyarázat → nincs blokk")
    void beyondToleranceWithExplanation() {
        assertThat(ClosingWizardService.closingDiscrepancyBlockReason(
                new BigDecimal("1500"), "Reggeli váltópénz eltérés, igazgatói jóváhagyással", TOL)).isNull();
    }

    // ============ FK-063 FR-3/FR-4: pénznemenkénti gate ============

    @Test
    @DisplayName("FK-063: üres / null pénznemenkénti térkép → nincs blokk")
    void perCurrency_emptyMap() {
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(null, null, TOL)).isNull();
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(Map.of(), null, TOL)).isNull();
    }

    @Test
    @DisplayName("FK-063 FR-3: minden pénznem 0 eltérés → nincs blokk")
    void perCurrency_allZero() {
        Map<String, BigDecimal> diffs = new LinkedHashMap<>();
        diffs.put("HUF", BigDecimal.ZERO);
        diffs.put("EUR", BigDecimal.ZERO);
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(diffs, null, TOL)).isNull();
    }

    @Test
    @DisplayName("FK-063: HUF 1 Ft-os kerekítési eltérés tolerálva")
    void perCurrency_hufWithinTolerance() {
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(
                Map.of("HUF", new BigDecimal("-1")), null, TOL)).isNull();
    }

    @Test
    @DisplayName("FK-063 FR-4: EUR-eltérés → blokk, az üzenet nevesíti az EUR-t")
    void perCurrency_eurMismatchBlocksNamingEur() {
        Map<String, BigDecimal> diffs = new LinkedHashMap<>();
        diffs.put("HUF", BigDecimal.ZERO);
        diffs.put("EUR", new BigDecimal("-50"));
        String reason = ClosingWizardService.perCurrencyDiscrepancyBlockReason(diffs, null, TOL);
        assertThat(reason).isNotNull().contains("EUR").contains("-50").contains("magyarázat");
    }

    @Test
    @DisplayName("FK-063: nem-HUF pénznemre nincs tolerancia (1 egység eltérés is blokkol)")
    void perCurrency_nonHufNoTolerance() {
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(
                Map.of("USD", new BigDecimal("1")), null, TOL)).isNotNull().contains("USD");
    }

    @Test
    @DisplayName("FK-063: eltérés + van magyarázat → nincs blokk")
    void perCurrency_withExplanationNoBlock() {
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(
                Map.of("EUR", new BigDecimal("-50")), "Sérült bankjegy bevonva", TOL)).isNull();
    }

    @Test
    @DisplayName("FK-063: több hibás pénznem → mindegyik nevesítve az üzenetben")
    void perCurrency_multipleMismatchesAllNamed() {
        Map<String, BigDecimal> diffs = new LinkedHashMap<>();
        diffs.put("HUF", new BigDecimal("500"));
        diffs.put("EUR", new BigDecimal("-50"));
        diffs.put("USD", new BigDecimal("20"));
        String reason = ClosingWizardService.perCurrencyDiscrepancyBlockReason(diffs, null, TOL);
        assertThat(reason).isNotNull().contains("HUF").contains("EUR").contains("USD");
    }
}

package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

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
    @DisplayName("toleranciaon belüli eltérés → nincs blokk")
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
}

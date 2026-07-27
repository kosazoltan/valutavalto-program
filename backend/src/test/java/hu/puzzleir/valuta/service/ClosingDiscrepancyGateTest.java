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

    /**
     * FK-066 pontosítás: az 1 Ft a KÓD-SZINTŰ HUF-fallback-default (nincs system_parameter
     * sor), és FK-066 után is ez marad a fallback. A migrációs seed (CLOSING_TOLERANCE_HUF=5)
     * DB-szintű explicit érték — azt az 5-ös toleranciájú tesztek fedik lentebb.
     */
    private static final BigDecimal TOL = BigDecimal.ONE;

    /** FK-066: a seedelt explicit HUF-tolerancia (DB-érték) — explicit ágon >= blokkol. */
    private static final BigDecimal TOL_5 = new BigDecimal("5");

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

    // ============ FK-066: ág-függő operátor (KRITIKUS KORREKCIÓ) ============
    // A spec szerint KÉT operátor él, ágtól függően:
    //   * EXPLICIT ág (van system_parameter sor): |diff| >= tolerancia BLOKKOL —
    //     a pontosan egyező eltérés IS blokkol (FR-6 explicit követelmény);
    //     az utolsó átengedett érték |diff| == tolerancia-1.
    //   * FALLBACK ág (nincs sor): |diff| > tolerancia blokkol — a mai, változatlan
    //     viselkedés (a fenti TOL=1 tesztek ezt fedik).
    // A csupasz BigDecimal-paraméteres statikus helper ág-vak, ezért az explicit-ági
    // határesetek a branch-aware ClosingTolerance.blocks() közös döntési pontján
    // vannak fagyasztva (RED: a típus még nem létezik — fordítási hibával piros).

    @Test
    @DisplayName("FK-066: explicit ág — |diff|==tolerancia MÁR BLOKKOL, tolerancia-1 az utolsó átengedett")
    void explicitBranch_blocksAtEquality() {
        ClosingTolerance explicit5 = ClosingTolerance.explicitOf(TOL_5);
        assertThat(explicit5.blocks(new BigDecimal("4"))).isFalse();
        assertThat(explicit5.blocks(new BigDecimal("-4"))).isFalse();
        assertThat(explicit5.blocks(new BigDecimal("5"))).isTrue();
        assertThat(explicit5.blocks(new BigDecimal("-5"))).isTrue();
        assertThat(explicit5.blocks(new BigDecimal("6"))).isTrue();
    }

    @Test
    @DisplayName("FK-066: fallback ág — a mai > operátor változatlan (|diff|==tolerancia még átmegy)")
    void fallbackBranch_keepsStrictGreaterOperator() {
        ClosingTolerance fallback1 = ClosingTolerance.fallbackOf(TOL);
        assertThat(fallback1.blocks(BigDecimal.ONE)).isFalse();
        assertThat(fallback1.blocks(new BigDecimal("-1"))).isFalse();
        assertThat(fallback1.blocks(new BigDecimal("2"))).isTrue();
    }

    @Test
    @DisplayName("FK-066: nulla eltérés SOHA nem blokkol — explicit 0-toleranciánál sem")
    void zeroDiffNeverBlocks() {
        assertThat(ClosingTolerance.explicitOf(BigDecimal.ZERO).blocks(BigDecimal.ZERO)).isFalse();
        assertThat(ClosingTolerance.explicitOf(TOL_5).blocks(BigDecimal.ZERO)).isFalse();
        assertThat(ClosingTolerance.fallbackOf(BigDecimal.ZERO).blocks(BigDecimal.ZERO)).isFalse();
    }

    @Test
    @DisplayName("FK-066: a HUF-tolerancia nem szivárog át nem-HUF pénznemre (USD 1 egység 5-ös tol. mellett is blokkol)")
    void perCurrency_hufToleranceDoesNotLeakToNonHuf() {
        assertThat(ClosingWizardService.perCurrencyDiscrepancyBlockReason(
                Map.of("USD", new BigDecimal("1")), null, TOL_5)).isNotNull().contains("USD");
    }
}

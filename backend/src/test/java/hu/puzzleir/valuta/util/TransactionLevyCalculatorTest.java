package hu.puzzleir.valuta.util;

import hu.puzzleir.valuta.util.TransactionLevyCalculator.LevyAmounts;
import hu.puzzleir.valuta.util.TransactionLevyCalculator.LevyRate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-099 A-sorozat — tiszta illeték-számítás (WU1 RED → WU3 GREEN).
 *
 * <p>Seed-ráta (V384): alap 0.450 % / 20 000 Ft, kiegészítő 0.450 % / 20 000 Ft,
 * conversionSingleSide = true, effectiveFrom 2013-01-01 ⇒ threshold 4 444 445.</p>
 *
 * <p>C8: az illeték ADÓ — HALF_UP 0 tizedesre, majd cap. Az 5 Ft-os
 * készpénz-kerekítés ({@link HungarianRounding#roundToFive}) NEM alkalmazható:
 * az A8 pineli, hogy a 13 501 Ft NEM lesz 13 500/13 505.</p>
 */
class TransactionLevyCalculatorTest {

    private static final LocalDate SEED_FROM = LocalDate.of(2013, 1, 1);

    /** V384 seed: 0.45% / 20000 mindkét komponensre, conversionSingleSide = true. */
    private static final LevyRate SEED = new LevyRate(
            SEED_FROM,
            new BigDecimal("0.450"), new BigDecimal("20000.00"),
            new BigDecimal("0.450"), new BigDecimal("20000.00"),
            true);

    @Test
    @DisplayName("A1/FR-2: 3 000 000 Ft alap-illetéke 13 500 Ft")
    void a1_baseLevyOfThreeMillion() {
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("3000000"), SEED);
        assertThat(amounts.baseLevy()).isEqualByComparingTo("13500");
    }

    @Test
    @DisplayName("A2/FR-3: a kiegészítő illeték is 13 500, az összeg 27 000")
    void a2_supplementLevyAndSum() {
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("3000000"), SEED);
        assertThat(amounts.supplementLevy()).isEqualByComparingTo("13500");
        assertThat(amounts.baseLevy().add(amounts.supplementLevy())).isEqualByComparingTo("27000");
    }

    @Test
    @DisplayName("A3/FR-4: a kalkulátor típus-független — SELL-re ugyanazok a számok")
    void a3_calculatorIsTypeAgnostic() {
        // A SELL-bekötést a service-szintű B3 pineli; itt a kalkulátor típus-függetlensége.
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("3000000"), SEED);
        assertThat(amounts.baseLevy()).isEqualByComparingTo("13500");
        assertThat(amounts.supplementLevy()).isEqualByComparingTo("13500");
        assertThat(amounts.aboveThreshold()).isFalse();
    }

    @Test
    @DisplayName("A4/FR-6: 5 000 000 Ft-nál NEM arányosítunk — mindkét komponens a cap-en (20 000)")
    void a4_fiveMillionHitsBothCaps() {
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("5000000"), SEED);
        assertThat(amounts.baseLevy()).isEqualByComparingTo("20000");
        assertThat(amounts.supplementLevy()).isEqualByComparingTo("20000");
        assertThat(amounts.baseLevy().add(amounts.supplementLevy())).isEqualByComparingTo("40000");
        assertThat(amounts.aboveThreshold()).isTrue();
    }

    @Test
    @DisplayName("A5/FR-7: a számított küszöb seed-rátán pontosan 4 444 445 Ft")
    void a5_thresholdExact() {
        assertThat(TransactionLevyCalculator.thresholdHuf(SEED)).isEqualByComparingTo("4444445");
    }

    @Test
    @DisplayName("A6/FR-7/D4: 4 444 444 Ft még NORMÁL, de a kerekített alap-illeték már 20 000")
    void a6_justBelowThresholdStillNormalWithCappedLevy() {
        // 4 444 444 × 0.45% = 19 999.998 → HALF_UP → 20 000; a besorolás viszont
        // ARITMETIKAI (huf × rate < cap), tehát normál. D4 — ezt nem szabad
        // "javítani" kerekített összehasonlításra (a küszöb 4 444 334-re csúszna).
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("4444444"), SEED);
        assertThat(amounts.aboveThreshold()).isFalse();
        assertThat(amounts.baseLevy()).isEqualByComparingTo("20000");
    }

    @Test
    @DisplayName("A7/FR-7: 4 444 445 Ft már küszöb feletti, alap-illeték 20 000")
    void a7_atThresholdIsAbove() {
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("4444445"), SEED);
        assertThat(amounts.aboveThreshold()).isTrue();
        assertThat(amounts.baseLevy()).isEqualByComparingTo("20000");
    }

    @Test
    @DisplayName("A8/C8: 13 501 Ft NEM kap 5 Ft-os készpénz-kerekítést (nem lesz 13 500/13 505)")
    void a8_noCashRoundingOnLevy() {
        // 3 000 222 × 0.45% = 13 500.999 → HALF_UP → 13 501 (nem 13 500, nem 13 505).
        BigDecimal levy = TransactionLevyCalculator.component(
                new BigDecimal("3000222"), new BigDecimal("0.450"), new BigDecimal("20000"));
        assertThat(levy).isEqualByComparingTo("13501");
    }

    @Test
    @DisplayName("A9/él: 0 Ft illetéke 0/0, nem küszöb feletti")
    void a9_zeroAmount() {
        LevyAmounts amounts = TransactionLevyCalculator.compute(BigDecimal.ZERO, SEED);
        assertThat(amounts.baseLevy()).isEqualByComparingTo("0");
        assertThat(amounts.supplementLevy()).isEqualByComparingTo("0");
        assertThat(amounts.aboveThreshold()).isFalse();
    }

    @Test
    @DisplayName("A10/él: 0 ráta mellett a küszöb null és nincs divide-by-zero")
    void a10_zeroRateMeansUnreachableCap() {
        LevyRate zeroRate = new LevyRate(
                SEED_FROM,
                BigDecimal.ZERO, new BigDecimal("20000.00"),
                BigDecimal.ZERO, new BigDecimal("20000.00"),
                true);
        assertThat(TransactionLevyCalculator.thresholdHuf(zeroRate)).isNull();
        LevyAmounts amounts = TransactionLevyCalculator.compute(new BigDecimal("9999999"), zeroRate);
        assertThat(amounts.baseLevy()).isEqualByComparingTo("0");
        assertThat(amounts.supplementLevy()).isEqualByComparingTo("0");
        assertThat(amounts.aboveThreshold()).isFalse();
    }

    @Test
    @DisplayName("A11: a DESC-listából a date-n hatályos (legfrissebb <= date) sort adja")
    void a11_resolveRatePicksLatestEffectiveOnDate() {
        LevyRate may = new LevyRate(LocalDate.of(2026, 5, 1),
                new BigDecimal("0.300"), new BigDecimal("15000"),
                new BigDecimal("0.300"), new BigDecimal("15000"), true);
        LevyRate seed = SEED;
        var resolved = TransactionLevyCalculator.resolveRate(
                List.of(may, seed), LocalDate.of(2026, 4, 30));
        assertThat(resolved).contains(seed);
    }

    @Test
    @DisplayName("A12/D7: ha minden sor a date UTÁN lép hatályba, Optional.empty (fail-closed)")
    void a12_resolveRateEmptyWhenNoneEffective() {
        LevyRate future = new LevyRate(LocalDate.of(2026, 5, 1),
                new BigDecimal("0.300"), new BigDecimal("15000"),
                new BigDecimal("0.300"), new BigDecimal("15000"), true);
        var resolved = TransactionLevyCalculator.resolveRate(
                List.of(future), LocalDate.of(2026, 4, 30));
        assertThat(resolved).isEmpty();
    }
}

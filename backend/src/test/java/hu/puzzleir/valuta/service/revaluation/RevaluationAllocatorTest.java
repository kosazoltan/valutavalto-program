package hu.puzzleir.valuta.service.revaluation;

import hu.puzzleir.valuta.service.revaluation.RevaluationAllocator.Allocation;
import hu.puzzleir.valuta.service.revaluation.RevaluationAllocator.CashierDriver;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Az értéktári átértékelés lecsorgatásának (lehívás × árrés) tesztjei — invariáns: Σ == REVAL.
 */
class RevaluationAllocatorTest {

    private static BigDecimal sum(List<Allocation> a) {
        return a.stream().map(Allocation::allocatedReval).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private static Allocation forCashier(List<Allocation> a, String id) {
        return a.stream().filter(x -> x.cashierId().equals(id)).findFirst().orElseThrow();
    }

    @Test
    @DisplayName("lehívás×árrés súly — A (60000×5) > B (40000×3), Σ == REVAL (500000)")
    void testDrawnTimesSpread() {
        var drivers = List.of(
                new CashierDriver("A", new BigDecimal("60000"), new BigDecimal("5")),
                new CashierDriver("B", new BigDecimal("40000"), new BigDecimal("3")));

        var res = RevaluationAllocator.allocateCurrency("EUR", new BigDecimal("500000"), drivers);

        // w_A=300000, w_B=120000, Σ=420000 → A=357143, B=142857
        assertThat(forCashier(res, "A").allocatedReval()).isEqualByComparingTo("357143");
        assertThat(forCashier(res, "B").allocatedReval()).isEqualByComparingTo("142857");
        assertThat(sum(res)).isEqualByComparingTo("500000"); // INVARIÁNS: pontosan a REVAL
    }

    @Test
    @DisplayName("negatív REVAL (veszteség) is pontosan kiosztódik (Σ == −300000)")
    void testNegativeReval() {
        var drivers = List.of(
                new CashierDriver("A", new BigDecimal("100"), new BigDecimal("2")),
                new CashierDriver("B", new BigDecimal("100"), new BigDecimal("2")));

        var res = RevaluationAllocator.allocateCurrency("USD", new BigDecimal("-300000"), drivers);

        assertThat(sum(res)).isEqualByComparingTo("-300000");
        assertThat(forCashier(res, "A").allocatedReval()).isEqualByComparingTo("-150000");
    }

    @Test
    @DisplayName("negatív árrés floor 0-ra — nem fordítja meg az előjelet, a másik kapja")
    void testNegativeSpreadFloored() {
        var drivers = List.of(
                new CashierDriver("A", new BigDecimal("100"), new BigDecimal("-5")), // floor → 0 súly
                new CashierDriver("B", new BigDecimal("100"), new BigDecimal("4")));

        var res = RevaluationAllocator.allocateCurrency("EUR", new BigDecimal("100000"), drivers);

        assertThat(forCashier(res, "A").allocatedReval()).isEqualByComparingTo("0");
        assertThat(forCashier(res, "B").allocatedReval()).isEqualByComparingTo("100000");
        assertThat(sum(res)).isEqualByComparingTo("100000");
    }

    @Test
    @DisplayName("Σsúly==0 (nincs árrés) → fallback lehívott mennyiség arányában")
    void testFallbackToDrawn() {
        var drivers = List.of(
                new CashierDriver("A", new BigDecimal("70000"), BigDecimal.ZERO),
                new CashierDriver("B", new BigDecimal("30000"), BigDecimal.ZERO));

        var res = RevaluationAllocator.allocateCurrency("EUR", new BigDecimal("100000"), drivers);

        assertThat(forCashier(res, "A").allocatedReval()).isEqualByComparingTo("70000");
        assertThat(forCashier(res, "B").allocatedReval()).isEqualByComparingTo("30000");
        assertThat(sum(res)).isEqualByComparingTo("100000");
    }

    @Test
    @DisplayName("nincs lehívás és nincs árrés → egyenlő osztás, Σ pontos (kerekítés-korrekció)")
    void testFallbackEqualWithRounding() {
        var drivers = List.of(
                new CashierDriver("A", BigDecimal.ZERO, BigDecimal.ZERO),
                new CashierDriver("B", BigDecimal.ZERO, BigDecimal.ZERO),
                new CashierDriver("C", BigDecimal.ZERO, BigDecimal.ZERO));

        var res = RevaluationAllocator.allocateCurrency("EUR", new BigDecimal("100000"), drivers);

        // 100000/3 = 33333.33 → 33334+33333+33333 = 100000 (legnagyobb-maradék)
        assertThat(sum(res)).isEqualByComparingTo("100000");
    }

    @Test
    @DisplayName("REVAL == 0 → minden pénztár 0")
    void testZeroReval() {
        var drivers = List.of(new CashierDriver("A", new BigDecimal("100"), new BigDecimal("5")));
        var res = RevaluationAllocator.allocateCurrency("EUR", BigDecimal.ZERO, drivers);
        assertThat(sum(res)).isEqualByComparingTo("0");
    }
}

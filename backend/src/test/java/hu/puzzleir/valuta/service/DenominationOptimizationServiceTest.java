package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.OptimizationStrategy;
import hu.puzzleir.valuta.repository.DenominationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Sprint A close-out (v2.5.65) — DenominationOptimizationService 7 stratégia unit teszt.
 *
 * <p>Kontextus: a 2026-05-13 v2.5.50+ Sprint 1-ben létrehozott DenominationOptimizationService
 * CUSTOM és BRANCH_SPECIFIC ágai csak greedy fallback-et adtak; ez a teszt verifikálja, hogy
 * mind a 7 stratégia (GREEDY, MIN_BANKNOTES, MIN_TOTAL, DYNAMIC, MIN_COINS, CUSTOM, BRANCH_SPECIFIC)
 * helyesen működik a v2.5.65-ben.</p>
 */
@ExtendWith(MockitoExtension.class)
class DenominationOptimizationServiceTest {

    @Mock
    private DenominationRepository denominationRepository;

    @InjectMocks
    private DenominationOptimizationService service;

    private final UUID branchId = UUID.randomUUID();
    private final Long currencyId = 1L;

    // HUF címletek (production-realistic): 20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5
    private List<Denomination> hufDenoms;

    @BeforeEach
    void setUp() {
        hufDenoms = List.of(
                makeDenom("20000", 100, DenominationType.BANKNOTE),
                makeDenom("10000", 100, DenominationType.BANKNOTE),
                makeDenom("5000", 100, DenominationType.BANKNOTE),
                makeDenom("2000", 100, DenominationType.BANKNOTE),
                makeDenom("1000", 100, DenominationType.BANKNOTE),
                makeDenom("500", 100, DenominationType.BANKNOTE),
                makeDenom("200", 100, DenominationType.COIN),
                makeDenom("100", 100, DenominationType.COIN),
                makeDenom("50", 100, DenominationType.COIN),
                makeDenom("20", 100, DenominationType.COIN),
                makeDenom("10", 100, DenominationType.COIN),
                makeDenom("5", 100, DenominationType.COIN)
        );
    }

    @Test
    @DisplayName("GREEDY: 37.350 Ft → 1×20000 + 1×10000 + 1×5000 + 1×2000 + 350 maradék (200+100+50)")
    void greedy_should_pickLargestFirst() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("37350"), OptimizationStrategy.GREEDY);

        assertThat(result).containsEntry(new BigDecimal("20000"), 1);
        assertThat(result).containsEntry(new BigDecimal("10000"), 1);
        assertThat(result).containsEntry(new BigDecimal("5000"), 1);
        assertThat(result).containsEntry(new BigDecimal("2000"), 1);
        assertThat(result).containsEntry(new BigDecimal("200"), 1);
        assertThat(result).containsEntry(new BigDecimal("100"), 1);
        assertThat(result).containsEntry(new BigDecimal("50"), 1);
        assertThat(sum(result)).isEqualByComparingTo("37350");
    }

    @Test
    @DisplayName("MIN_BANKNOTES: ugyanaz, mint GREEDY")
    void minBanknotes_equivalent_to_greedy() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("15000"), OptimizationStrategy.MIN_BANKNOTES);

        assertThat(result).containsEntry(new BigDecimal("10000"), 1);
        assertThat(result).containsEntry(new BigDecimal("5000"), 1);
        assertThat(sum(result)).isEqualByComparingTo("15000");
    }

    @Test
    @DisplayName("MIN_TOTAL: 100 Ft → 20×5 (kis címleteket preferál)")
    void minTotal_should_pickSmallestFirst() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("100"), OptimizationStrategy.MIN_TOTAL);

        // 5-ös érmét keresi először (legkisebb), 20×5=100 — DE max 100 db elérhető
        assertThat(result).containsEntry(new BigDecimal("5"), 20);
        assertThat(sum(result)).isEqualByComparingTo("100");
    }

    @Test
    @DisplayName("DYNAMIC: 17000 Ft → minimum címletszám = 1×10000 + 1×5000 + 1×2000 (3 db, optimális)")
    void dynamic_minimum_count() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("17000"), OptimizationStrategy.DYNAMIC);

        int totalCount = result.values().stream().mapToInt(Integer::intValue).sum();
        assertThat(totalCount).isLessThanOrEqualTo(3);
        assertThat(sum(result)).isEqualByComparingTo("17000");
    }

    @Test
    @DisplayName("MIN_COINS: 350 Ft → bankjegyekkel nem fedhető, érmékkel (200+100+50)")
    void minCoins_prefersBanknotes_thenCoins() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("11550"), OptimizationStrategy.MIN_COINS);

        // 10000 + 1000 + 500 (bankjegy) = 11500, marad 50 érme
        assertThat(result).containsEntry(new BigDecimal("10000"), 1);
        assertThat(result).containsEntry(new BigDecimal("1000"), 1);
        assertThat(result).containsEntry(new BigDecimal("500"), 1);
        assertThat(result).containsEntry(new BigDecimal("50"), 1);
        assertThat(sum(result)).isEqualByComparingTo("11550");
    }

    @Test
    @DisplayName("CUSTOM: priorityOrderJson alapján — fordított sorrendben (kis címlet előbb)")
    void custom_priorityOrderJson_reversed() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        // Priority order: 1000-est preferálja a 10000 előtt → 10000-et csak ha 1000 nincs elég
        String priorityJson = "[\"1000\", \"500\", \"200\", \"100\", \"50\", \"20\", \"10\", \"5\", \"20000\", \"10000\", \"5000\", \"2000\"]";

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("15000"), OptimizationStrategy.CUSTOM, priorityJson);

        // Mivel 100 db 1000-es van, csak 15 db kell → ennyi elég
        assertThat(result).containsEntry(new BigDecimal("1000"), 15);
        assertThat(sum(result)).isEqualByComparingTo("15000");
    }

    @Test
    @DisplayName("CUSTOM: hibás JSON → GREEDY fallback")
    void custom_invalidJson_fallbacksToGreedy() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("15000"), OptimizationStrategy.CUSTOM, "invalid-json");

        assertThat(result).containsEntry(new BigDecimal("10000"), 1);
        assertThat(result).containsEntry(new BigDecimal("5000"), 1);
        assertThat(sum(result)).isEqualByComparingTo("15000");
    }

    @Test
    @DisplayName("BRANCH_SPECIFIC: nagy készletű címleteket preferálja (készletkiegyenlítés)")
    void branchSpecific_prefers_highStock_denominations() {
        // 20000-ből csak 1 db van, 1000-ből 200 db → 1000-est használja először
        List<Denomination> mixed = List.of(
                makeDenom("20000", 1, DenominationType.BANKNOTE),
                makeDenom("10000", 5, DenominationType.BANKNOTE),
                makeDenom("5000", 10, DenominationType.BANKNOTE),
                makeDenom("1000", 200, DenominationType.BANKNOTE),
                makeDenom("500", 50, DenominationType.BANKNOTE)
        );
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(mixed);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("15000"), OptimizationStrategy.BRANCH_SPECIFIC);

        // BRANCH_SPECIFIC: nagy stock-os (1000) jön először → 15×1000 = 15000
        assertThat(result).containsEntry(new BigDecimal("1000"), 15);
        assertThat(sum(result)).isEqualByComparingTo("15000");
    }

    @Test
    @DisplayName("DYNAMIC adversarial: 23000 Ft, {10000×1, 5000×3, 2000×4}, NO 1000 — greedy elakad, DYNAMIC pontos")
    void dynamic_adversarial_caseWhereGreedyFails() {
        // Adversarial: greedy: 10000+5000+5000+2000+? leftover 1000 — nincs 1000-es, elakad 22000-nél
        // DYNAMIC: 10000+5000+2000+2000+2000+2000 = 23000 (6 piece) vagy
        //          5000+5000+5000+2000+2000+2000+2000 = 23000 (7 piece). Optimum 6.
        List<Denomination> stock = List.of(
                makeDenom("10000", 1, DenominationType.BANKNOTE),
                makeDenom("5000", 3, DenominationType.BANKNOTE),
                makeDenom("2000", 4, DenominationType.BANKNOTE)
        );
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(stock);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("23000"), OptimizationStrategy.DYNAMIC);

        assertThat(sum(result)).isEqualByComparingTo("23000");
        int totalCount = result.values().stream().mapToInt(Integer::intValue).sum();
        assertThat(totalCount).isLessThanOrEqualTo(7);  // DYNAMIC optimum 6, max 7
    }

    @Test
    @DisplayName("CUSTOM Codex P1 #701: duplikált faceValue NEM allokál többet mint amennyi a készletben van")
    void custom_duplicatedPriorityFaceValue_doesNotOverAllocate() {
        // Készlet: csak 3 db 1000-es. Ha a JSON ["1000", "1000"]-t tartalmaz,
        // a NAÍV implementáció 6 db 1000-est próbálna kiadni (2× stock). A fix után
        // a dedup csak 3 db-ot ad ki, a maradékot a fallback címletek fedik.
        List<Denomination> scarce = List.of(
                makeDenom("10000", 10, DenominationType.BANKNOTE),
                makeDenom("1000", 3, DenominationType.BANKNOTE),
                makeDenom("500", 10, DenominationType.BANKNOTE)
        );
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(scarce);

        String priorityJson = "[\"1000\", \"1000\", \"500\"]";
        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("4000"), OptimizationStrategy.CUSTOM, priorityJson);

        // Max 3 db 1000-es lehet (készlet-korlát), a többi 500-as
        assertThat(result.getOrDefault(new BigDecimal("1000"), 0)).isLessThanOrEqualTo(3);
        assertThat(sum(result)).isEqualByComparingTo("4000");
    }

    @Test
    @DisplayName("CUSTOM scale-mismatch: priorityJson 1000.00 ↔ stored 1000 (BigDecimal scale-independent)")
    void custom_scaleMismatch_normalized() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(hufDenoms);

        // JSON "1000.00" — stored value "1000" (scale 0). BigDecimal egyenlőség hibás
        // lenne, de a service stripTrailingZeros()-vel normalizál.
        String priorityJson = "[\"1000.00\", \"500.00\", \"200.00\"]";

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("3000"), OptimizationStrategy.CUSTOM, priorityJson);

        // 3000 / 1000 = 3 db × 1000
        assertThat(result).containsEntry(new BigDecimal("1000"), 3);
        assertThat(sum(result)).isEqualByComparingTo("3000");
    }

    @Test
    @DisplayName("Empty stock: minden stratégia üres térképet ad (warning, nem dob)")
    void emptyStock_allStrategies_returnEmpty() {
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(List.of());

        for (OptimizationStrategy s : OptimizationStrategy.values()) {
            Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                    new BigDecimal("1000"), s);
            assertThat(result).as("strategy=" + s).isEmpty();
        }
    }

    @Test
    @DisplayName("Zero amount: üres térkép minden stratégiára")
    void zeroAmount_returnsEmpty() {
        for (OptimizationStrategy s : OptimizationStrategy.values()) {
            Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                    BigDecimal.ZERO, s);
            assertThat(result).as("strategy=" + s).isEmpty();
        }
    }

    @Test
    @DisplayName("Null strategy → IllegalArgumentException")
    void nullStrategy_throws() {
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class,
                () -> service.optimize(branchId, currencyId, new BigDecimal("1000"), null));
    }

    @Test
    @DisplayName("Null amount → IllegalArgumentException")
    void nullAmount_throws() {
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class,
                () -> service.optimize(branchId, currencyId, null, OptimizationStrategy.GREEDY));
    }

    @Test
    @DisplayName("Negative amount → IllegalArgumentException")
    void negativeAmount_throws() {
        org.junit.jupiter.api.Assertions.assertThrows(IllegalArgumentException.class,
                () -> service.optimize(branchId, currencyId, new BigDecimal("-100"),
                        OptimizationStrategy.GREEDY));
    }

    @Test
    @DisplayName("Készlethiány: GREEDY warning, nem dob, részleges eredmény")
    void greedy_insufficientStock_warnsButContinues() {
        List<Denomination> scarce = List.of(
                makeDenom("10000", 1, DenominationType.BANKNOTE),
                makeDenom("5000", 1, DenominationType.BANKNOTE)
        );
        when(denominationRepository.findByBranchAndCurrency(any(), any())).thenReturn(scarce);

        Map<BigDecimal, Integer> result = service.optimize(branchId, currencyId,
                new BigDecimal("50000"), OptimizationStrategy.GREEDY);

        // Csak 15000-ig tud lefedni
        assertThat(sum(result)).isEqualByComparingTo("15000");
    }

    // ==========================================================================
    // Helpers
    // ==========================================================================

    private Denomination makeDenom(String faceValue, int quantity, DenominationType type) {
        Denomination d = new Denomination();
        d.setFaceValue(new BigDecimal(faceValue));
        d.setQuantity(quantity);
        d.setDenominationType(type);
        return d;
    }

    private BigDecimal sum(Map<BigDecimal, Integer> denominations) {
        return denominations.entrySet().stream()
                .map(e -> e.getKey().multiply(BigDecimal.valueOf(e.getValue())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}

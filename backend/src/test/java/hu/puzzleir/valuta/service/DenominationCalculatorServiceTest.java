package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * DenominationCalculatorService UNIT tesztek.
 *
 * Teszteli a KELLCIM (Kellő Címlet) algoritmust:
 * - Greedy: legnagyobb címlettől indul
 * - Balanced: készlet-figyelő
 * - Maradék kezelés
 * - Üres/null input
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DenominationCalculatorServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Mock private DenominationRepository denominationRepository;
    @InjectMocks private DenominationCalculatorService calculatorService;

    @BeforeEach
    void setUp() {
        var details = new WorkerAuthenticationDetails(1L, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("user", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("Greedy: 15.000 Ft → 1×10000 + 1×5000")
    void greedyShouldReturnOptimalDenominations() {
        when(denominationRepository.findByCompanyIdAndCurrencyCode(any(UUID.class), eq("HUF"))).thenReturn(hufDenominations());

        Map<BigDecimal, Integer> result = calculatorService.calculateGreedy("HUF", new BigDecimal("15000"));

        assertThat(result).containsEntry(new BigDecimal("10000"), 1);
        assertThat(result).containsEntry(new BigDecimal("5000"), 1);
    }

    @Test
    @DisplayName("Greedy: 37.500 Ft → 1×20000 + 1×10000 + 1×5000 + 1×2000 + 1×500")
    void greedyShouldHandleMultipleDenominations() {
        when(denominationRepository.findByCompanyIdAndCurrencyCode(any(UUID.class), eq("HUF"))).thenReturn(hufDenominations());

        Map<BigDecimal, Integer> result = calculatorService.calculateGreedy("HUF", new BigDecimal("37500"));

        assertThat(result).containsEntry(new BigDecimal("20000"), 1);
        assertThat(result).containsEntry(new BigDecimal("10000"), 1);
        assertThat(result).containsEntry(new BigDecimal("5000"), 1);
        assertThat(result).containsEntry(new BigDecimal("2000"), 1);
        assertThat(result).containsEntry(new BigDecimal("500"), 1);

        BigDecimal sum = calculatorService.sumDenominations(result);
        assertThat(sum).isEqualByComparingTo("37500");
    }

    @Test
    @DisplayName("Greedy: 0 Ft → üres eredmény")
    void greedyShouldReturnEmptyForZero() {
        Map<BigDecimal, Integer> result = calculatorService.calculateGreedy("HUF", BigDecimal.ZERO);
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Greedy: null → üres eredmény")
    void greedyShouldReturnEmptyForNull() {
        Map<BigDecimal, Integer> result = calculatorService.calculateGreedy("HUF", null);
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Greedy: negatív → üres eredmény")
    void greedyShouldReturnEmptyForNegative() {
        Map<BigDecimal, Integer> result = calculatorService.calculateGreedy("HUF", new BigDecimal("-5000"));
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Balanced: készlet limittel dolgozik")
    void balancedShouldRespectStockLimits() {
        when(denominationRepository.findByCompanyIdAndCurrencyCode(any(UUID.class), eq("HUF"))).thenReturn(hufDenominations());

        // Csak 1 db 20.000-es van → max 0-t ad ki belőle (50% = 0.5 → 1)
        Map<BigDecimal, Integer> stock = Map.of(
                new BigDecimal("20000"), 2,
                new BigDecimal("10000"), 20,
                new BigDecimal("5000"), 50
        );

        Map<BigDecimal, Integer> result = calculatorService.calculateBalanced(
                "HUF", new BigDecimal("50000"), stock);

        BigDecimal sum = calculatorService.sumDenominations(result);
        assertThat(sum).isEqualByComparingTo("50000");
    }

    @Test
    @DisplayName("sumDenominations: helyes összeg")
    void sumShouldBeCorrect() {
        Map<BigDecimal, Integer> denoms = Map.of(
                new BigDecimal("10000"), 2,
                new BigDecimal("5000"), 1,
                new BigDecimal("1000"), 3
        );

        BigDecimal sum = calculatorService.sumDenominations(denoms);
        assertThat(sum).isEqualByComparingTo("28000");
    }

    // === Helper: HUF címletek ===

    private List<Denomination> hufDenominations() {
        Currency huf = new Currency();
        huf.setCode("HUF");

        return new java.util.ArrayList<>(List.of(
                createDenom(huf, "20000", true),
                createDenom(huf, "10000", true),
                createDenom(huf, "5000", true),
                createDenom(huf, "2000", true),
                createDenom(huf, "1000", true),
                createDenom(huf, "500", true),
                createDenom(huf, "200", true),
                createDenom(huf, "100", true)
        ));
    }

    private Denomination createDenom(Currency currency, String faceValue, boolean active) {
        Denomination d = new Denomination();
        d.setCurrency(currency);
        d.setFaceValue(new BigDecimal(faceValue));
        d.setActive(active);
        d.setDenominationType(DenominationType.BANKNOTE);
        d.setQuantity(100);
        return d;
    }
}

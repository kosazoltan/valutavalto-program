package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DenominationOptimization;
import hu.puzzleir.valuta.entity.DenominationRule;
import hu.puzzleir.valuta.entity.DenominationRuleType;
import hu.puzzleir.valuta.entity.OptimizationStrategy;
import hu.puzzleir.valuta.repository.DenominationOptimizationRepository;
import hu.puzzleir.valuta.repository.DenominationRuleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * Sprint 1: címletezési szabály-kiválasztó service tesztek.
 * v2.0 spec 07_cimletkezeles.md alapján.
 */
@ExtendWith(MockitoExtension.class)
class DenominationRuleSelectionServiceTest {

    @Mock private DenominationRuleRepository ruleRepository;
    @Mock private DenominationOptimizationRepository optimizationRepository;

    @InjectMocks
    private DenominationRuleSelectionService service;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long EUR_ID = 2L;

    @BeforeEach
    void setUp() {
        // Default: nincs matching rule, van default optimization (GREEDY)
        when(ruleRepository.findMatchingRules(any(), any(), any())).thenReturn(List.of());
    }

    @Test
    @DisplayName("Matching rule → annak strategy-jét adja vissza")
    void matchingRule_returnsItsStrategy() {
        DenominationOptimization opt = DenominationOptimization.builder()
                .name("DYNAMIC default")
                .strategy(OptimizationStrategy.DYNAMIC)
                .isDefault(false)
                .isActive(true)
                .build();
        DenominationRule rule = DenominationRule.builder()
                .ruleName("VIP DYNAMIC")
                .ruleType(DenominationRuleType.CUSTOMER_TYPE)
                .optimization(opt)
                .priority(10)
                .isActive(true)
                .build();
        rule.setId(UUID.randomUUID());
        when(ruleRepository.findMatchingRules(eq(BRANCH_ID), eq(EUR_ID), eq(new BigDecimal("100000"))))
                .thenReturn(List.of(rule));

        var result = service.selectStrategy(BRANCH_ID, EUR_ID, new BigDecimal("100000"));

        assertThat(result.getStrategy()).isEqualTo(OptimizationStrategy.DYNAMIC);
        assertThat(result.getRuleName()).isEqualTo("VIP DYNAMIC");
        assertThat(result.getSource()).isEqualTo("RULE_MATCH");
    }

    @Test
    @DisplayName("Nincs matching rule → default optimization")
    void noRule_returnsDefaultOptimization() {
        DenominationOptimization defaultOpt = DenominationOptimization.builder()
                .name("GREEDY default")
                .strategy(OptimizationStrategy.GREEDY)
                .isDefault(true)
                .isActive(true)
                .build();
        when(optimizationRepository.findByIsDefaultTrueAndIsActiveTrue()).thenReturn(Optional.of(defaultOpt));

        var result = service.selectStrategy(BRANCH_ID, EUR_ID, new BigDecimal("50000"));

        assertThat(result.getStrategy()).isEqualTo(OptimizationStrategy.GREEDY);
        assertThat(result.getOptimizationName()).isEqualTo("GREEDY default");
        assertThat(result.getSource()).isEqualTo("DEFAULT_OPTIMIZATION");
    }

    @Test
    @DisplayName("Sem rule, sem default → hard fallback GREEDY")
    void noRuleNoDefault_returnsHardFallback() {
        when(optimizationRepository.findByIsDefaultTrueAndIsActiveTrue()).thenReturn(Optional.empty());

        var result = service.selectStrategy(BRANCH_ID, EUR_ID, new BigDecimal("50000"));

        assertThat(result.getStrategy()).isEqualTo(OptimizationStrategy.GREEDY);
        assertThat(result.getSource()).isEqualTo("HARD_FALLBACK");
    }

    @Test
    @DisplayName("Több matching rule közül a legfontosabb (legalacsonyabb priority) nyer")
    void multipleMatching_lowestPriorityWins() {
        DenominationOptimization opt1 = DenominationOptimization.builder()
                .name("MIN_COINS").strategy(OptimizationStrategy.MIN_COINS).isActive(true).build();
        DenominationOptimization opt2 = DenominationOptimization.builder()
                .name("MIN_BANKNOTES").strategy(OptimizationStrategy.MIN_BANKNOTES).isActive(true).build();

        DenominationRule rule1 = DenominationRule.builder()
                .ruleName("Branch override").priority(5).optimization(opt1)
                .isActive(true).build();
        rule1.setId(UUID.randomUUID());
        DenominationRule rule2 = DenominationRule.builder()
                .ruleName("Default rule").priority(100).optimization(opt2)
                .isActive(true).build();
        rule2.setId(UUID.randomUUID());

        // A repository ORDER BY priority ASC szerinti listát ad — első a legkisebb
        when(ruleRepository.findMatchingRules(any(), any(), any())).thenReturn(List.of(rule1, rule2));

        var result = service.selectStrategy(BRANCH_ID, EUR_ID, new BigDecimal("10000"));

        assertThat(result.getStrategy()).isEqualTo(OptimizationStrategy.MIN_COINS);
        assertThat(result.getRuleName()).isEqualTo("Branch override");
    }
}

package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.DenominationOptimization;
import hu.puzzleir.valuta.entity.DenominationRule;
import hu.puzzleir.valuta.entity.OptimizationStrategy;
import hu.puzzleir.valuta.repository.DenominationOptimizationRepository;
import hu.puzzleir.valuta.repository.DenominationRuleRepository;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Címletezési szabály-kiválasztás — egy adott tranzakcióhoz meghatározza,
 * melyik OptimizationStrategy-t kell alkalmazni.
 *
 * <p>v2.0 specifikáció 07_cimletkezeles.md:
 * <ol>
 *   <li>Branch-specifikus szabály felüljárja az általánost</li>
 *   <li>Currency-specifikus szabály felüljárja az általánost</li>
 *   <li>Amount range matching</li>
 *   <li>Ha nincs match → DenominationOptimization is_default=true</li>
 *   <li>Ha az sincs → GREEDY hard fallback</li>
 * </ol></p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class DenominationRuleSelectionService {

    private final DenominationRuleRepository ruleRepository;
    private final DenominationOptimizationRepository optimizationRepository;

    /**
     * Stratégia kiválasztása egy adott tranzakcióhoz.
     */
    public RuleSelectionResult selectStrategy(UUID branchId, Long currencyId, BigDecimal hufAmount) {
        // 1. Próbáljuk a szabályok közül a leginkább specifikust
        List<DenominationRule> matching = ruleRepository.findMatchingRules(branchId, currencyId, hufAmount);
        if (!matching.isEmpty()) {
            DenominationRule rule = matching.get(0);
            DenominationOptimization opt = rule.getOptimization();
            log.debug("Címletezési szabály: rule={} → strategy={}", rule.getRuleName(), opt.getStrategy());
            return RuleSelectionResult.builder()
                    .strategy(opt.getStrategy())
                    .ruleId(rule.getId())
                    .ruleName(rule.getRuleName())
                    .optimizationName(opt.getName())
                    .source("RULE_MATCH")
                    .build();
        }

        // 2. Fallback: alapértelmezett optimization
        return optimizationRepository.findByIsDefaultTrueAndIsActiveTrue()
                .map(opt -> RuleSelectionResult.builder()
                        .strategy(opt.getStrategy())
                        .optimizationName(opt.getName())
                        .source("DEFAULT_OPTIMIZATION")
                        .build())
                // 3. Hard fallback
                .orElseGet(() -> {
                    log.warn("Nincs aktív alapértelmezett címletezési stratégia — GREEDY hard fallback");
                    return RuleSelectionResult.builder()
                            .strategy(OptimizationStrategy.GREEDY)
                            .source("HARD_FALLBACK")
                            .build();
                });
    }

    @Data
    @Builder
    @AllArgsConstructor
    public static class RuleSelectionResult {
        private OptimizationStrategy strategy;
        private UUID ruleId;
        private String ruleName;
        private String optimizationName;
        /** RULE_MATCH | DEFAULT_OPTIMIZATION | HARD_FALLBACK */
        private String source;
    }
}

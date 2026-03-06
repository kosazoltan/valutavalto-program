package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.rounding.RoundingRuleDto;
import hu.puzzleir.valuta.entity.RoundingRule;
import hu.puzzleir.valuta.repository.RoundingRuleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Kerekítési szabályok szolgáltatás.
 *
 * Valutánként definiált kerekítési pontossággal és irány-szabályokkal dolgozik.
 * - EUR/USD/GBP/CHF: 0.01 pontosság
 * - CZK/PLN/RON/HRK: 0.1 pontosság
 * - Kis összeg (<100 egység): felkerekítés
 * - Nagy összeg (>10000 egység): lefelé kerekítés (cég javára)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class RoundingRuleService {

    private final RoundingRuleRepository roundingRuleRepository;

    /**
     * Kerekítési szabály lekérése valutakód alapján.
     * Ha nincs szabály definiálva, alapértelmezett 0.01/HALF_UP-ot ad.
     */
    public RoundingRuleDto getRoundingRule(String currencyCode, BigDecimal amount) {
        RoundingRule rule = roundingRuleRepository.findByCurrencyCode(currencyCode)
                .orElse(defaultRule(currencyCode));

        return toDto(rule);
    }

    /**
     * Összeg kerekítése a valuta szabálya szerint.
     *
     * @param currencyCode valutakód
     * @param amount kerekítendő összeg
     * @param direction "BUY" vagy "SELL" — a cég szemszögéből
     * @return kerekített összeg
     */
    public BigDecimal roundAmount(String currencyCode, BigDecimal amount, String direction) {
        RoundingRule rule = roundingRuleRepository.findByCurrencyCode(currencyCode)
                .orElse(defaultRule(currencyCode));

        BigDecimal precision = rule.getPrecisionValue();
        RoundingMode mode = resolveRoundingMode(rule, amount);

        // Kerekítés a precízió egységére
        // pl. 0.01 → 2 tizedesjegy, 0.1 → 1 tizedesjegy
        int scale = precision.stripTrailingZeros().scale();
        if (scale < 0) scale = 0;

        return amount.setScale(scale, mode);
    }

    /**
     * Összes kerekítési szabály lekérése.
     */
    public List<RoundingRuleDto> getAllRules() {
        return roundingRuleRepository.findAll().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPER METHODS ============

    private RoundingMode resolveRoundingMode(RoundingRule rule, BigDecimal amount) {
        BigDecimal absAmount = amount.abs();

        if (absAmount.compareTo(rule.getSmallThreshold()) < 0) {
            return parseRoundingMode(rule.getSmallRounding());
        }
        if (absAmount.compareTo(rule.getLargeThreshold()) > 0) {
            return parseRoundingMode(rule.getLargeRounding());
        }
        return RoundingMode.HALF_UP;
    }

    private RoundingMode parseRoundingMode(String mode) {
        return switch (mode.toUpperCase()) {
            case "UP" -> RoundingMode.UP;
            case "DOWN" -> RoundingMode.DOWN;
            case "CEILING" -> RoundingMode.CEILING;
            case "FLOOR" -> RoundingMode.FLOOR;
            default -> RoundingMode.HALF_UP;
        };
    }

    private RoundingRule defaultRule(String currencyCode) {
        return RoundingRule.builder()
                .currencyCode(currencyCode)
                .precisionValue(new BigDecimal("0.01"))
                .smallThreshold(new BigDecimal("100"))
                .largeThreshold(new BigDecimal("10000"))
                .smallRounding("UP")
                .largeRounding("DOWN")
                .build();
    }

    private RoundingRuleDto toDto(RoundingRule entity) {
        return RoundingRuleDto.builder()
                .id(entity.getId())
                .currencyCode(entity.getCurrencyCode())
                .precisionValue(entity.getPrecisionValue())
                .smallThreshold(entity.getSmallThreshold())
                .largeThreshold(entity.getLargeThreshold())
                .smallRounding(entity.getSmallRounding())
                .largeRounding(entity.getLargeRounding())
                .build();
    }
}

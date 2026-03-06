package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.rounding.RoundingRuleDto;
import hu.puzzleir.valuta.service.RoundingRuleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Kerekítési szabályok controller.
 */
@RestController
@RequestMapping("/api/v1/rounding-rules")
@RequiredArgsConstructor
public class RoundingRuleController {

    private final RoundingRuleService roundingRuleService;

    /**
     * Összes kerekítési szabály
     *
     * GET /api/v1/rounding-rules
     */
    @GetMapping
    public ResponseEntity<List<RoundingRuleDto>> getAllRules() {
        return ResponseEntity.ok(roundingRuleService.getAllRules());
    }

    /**
     * Kerekítési szabály lekérése valutakód alapján
     *
     * GET /api/v1/rounding-rules/{currencyCode}?amount=100
     */
    @GetMapping("/{currencyCode}")
    public ResponseEntity<RoundingRuleDto> getRule(
            @PathVariable String currencyCode,
            @RequestParam(defaultValue = "0") BigDecimal amount) {
        return ResponseEntity.ok(roundingRuleService.getRoundingRule(currencyCode, amount));
    }

    /**
     * Összeg kerekítése
     *
     * POST /api/v1/rounding-rules/round
     */
    @PostMapping("/round")
    public ResponseEntity<Map<String, BigDecimal>> roundAmount(
            @RequestParam String currencyCode,
            @RequestParam BigDecimal amount,
            @RequestParam(defaultValue = "BUY") String direction) {
        BigDecimal rounded = roundingRuleService.roundAmount(currencyCode, amount, direction);
        return ResponseEntity.ok(Map.of("original", amount, "rounded", rounded));
    }
}

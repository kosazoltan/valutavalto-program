package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.DenominationCalculatorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Címlet kalkulátor REST API.
 *
 * Legacy: KELLCIM — optimális címlet összetétel javaslat.
 */
@RestController
@RequestMapping("/api/denomination-calculator")
@RequiredArgsConstructor
@Tag(name = "Címlet kalkulátor", description = "Optimális címlet összetétel számítás")
public class DenominationCalculatorController {

    private final DenominationCalculatorService calculatorService;

    @GetMapping("/suggest")
    @Operation(summary = "Greedy címlet javaslat")
    public ResponseEntity<CalculationResult> suggest(
            @RequestParam String currencyCode,
            @RequestParam BigDecimal amount) {

        Map<BigDecimal, Integer> result = calculatorService.calculateGreedy(currencyCode, amount);
        BigDecimal total = calculatorService.sumDenominations(result);
        BigDecimal remainder = amount.subtract(total);

        return ResponseEntity.ok(new CalculationResult(
                currencyCode, amount, result, total, remainder));
    }

    @PostMapping("/suggest-balanced")
    @Operation(summary = "Készlet-figyelő címlet javaslat")
    public ResponseEntity<CalculationResult> suggestBalanced(
            @Valid @RequestBody BalancedRequest request) {

        Map<BigDecimal, Integer> result = calculatorService.calculateBalanced(
                request.currencyCode(), request.amount(), request.availableStock());
        BigDecimal total = calculatorService.sumDenominations(result);
        BigDecimal remainder = request.amount().subtract(total);

        return ResponseEntity.ok(new CalculationResult(
                request.currencyCode(), request.amount(), result, total, remainder));
    }

    // --- DTOs ---
    record CalculationResult(
        String currencyCode,
        BigDecimal requestedAmount,
        Map<BigDecimal, Integer> denominations,
        BigDecimal totalAmount,
        BigDecimal remainder
    ) {}

    record BalancedRequest(
        String currencyCode,
        BigDecimal amount,
        Map<BigDecimal, Integer> availableStock
    ) {}
}

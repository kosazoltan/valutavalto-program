package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.calculator.CalculationResultDto;
import hu.puzzleir.valuta.dto.calculator.ConvertRequestDto;
import hu.puzzleir.valuta.dto.calculator.ReverseRequestDto;
import hu.puzzleir.valuta.service.CurrencyCalculatorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Deviza átváltás kalkulátor controller.
 */
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/calculator")
@RequiredArgsConstructor
public class CurrencyCalculatorController {

    private final CurrencyCalculatorService currencyCalculatorService;

    /**
     * Deviza átváltás kalkuláció
     *
     * POST /api/v1/calculator/convert
     */
    @PostMapping("/convert")
    public ResponseEntity<CalculationResultDto> convert(@Valid @RequestBody ConvertRequestDto request) {
        CalculationResultDto result = currencyCalculatorService.calculate(
                request.getFromCurrency(),
                request.getToCurrency(),
                request.getAmount(),
                request.getDirection()
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Fordított kalkuláció: mennyi devizát kap X forintért
     *
     * POST /api/v1/calculator/reverse
     */
    @PostMapping("/reverse")
    @SuppressWarnings("unchecked")
    public ResponseEntity<Map<String, Object>> reverse(@Valid @RequestBody ReverseRequestDto request) {
        BigDecimal foreignAmount = currencyCalculatorService.calculateReverse(
                request.getCurrency(),
                request.getHufAmount()
        );
        Map<String, Object> result = new java.util.LinkedHashMap<>();
        result.put("currency", request.getCurrency());
        result.put("hufAmount", request.getHufAmount());
        result.put("foreignAmount", foreignAmount);
        return ResponseEntity.ok(result);
    }

    /**
     * Összes valutapár cross-rate mátrix
     *
     * GET /api/v1/calculator/matrix
     */
    @GetMapping("/matrix")
    public ResponseEntity<Map<String, Map<String, BigDecimal>>> getMatrix() {
        return ResponseEntity.ok(currencyCalculatorService.getExchangeMatrix());
    }
}

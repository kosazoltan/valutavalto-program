package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.calculator.CalculationResultDto;
import hu.puzzleir.valuta.dto.calculator.ConvertRequestDto;
import hu.puzzleir.valuta.dto.calculator.ReverseRequestDto;
import hu.puzzleir.valuta.service.CurrencyCalculatorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;

/**
 * Deviza átváltás kalkulátor controller.
 */
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
    public ResponseEntity<CalculationResultDto> convert(@RequestBody ConvertRequestDto request) {
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
    public ResponseEntity<Map<String, BigDecimal>> reverse(@RequestBody ReverseRequestDto request) {
        BigDecimal foreignAmount = currencyCalculatorService.calculateReverse(
                request.getCurrency(),
                request.getHufAmount()
        );
        return ResponseEntity.ok(Map.of(
                "currency", BigDecimal.ZERO, // placeholder for code
                "hufAmount", request.getHufAmount(),
                "foreignAmount", foreignAmount
        ));
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

package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.exchangerate.CreateExchangeRateDto;
import hu.puzzleir.valuta.dto.exchangerate.ExchangeRateDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.mapper.ExchangeRateMapper;
import hu.puzzleir.valuta.service.ExchangeRateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Árfolyam controller
 *
 * Legacy: ARFOLYAM tábla kezelés
 */
@RestController
@RequestMapping("/api/v1/exchange-rates")
@RequiredArgsConstructor
public class ExchangeRateController {

    private final ExchangeRateService exchangeRateService;
    private final ExchangeRateMapper exchangeRateMapper;

    /**
     * Összes aktuális árfolyam
     *
     * GET /api/v1/exchange-rates
     */
    @GetMapping
    public ResponseEntity<List<ExchangeRateDto>> getAllCurrentRates() {
        List<ExchangeRate> rates = exchangeRateService.getAllCurrentRates();
        List<ExchangeRateDto> dtos = rates.stream()
                .map(exchangeRateMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Árfolyam valuta ID alapján
     *
     * GET /api/v1/exchange-rates/currency/{currencyId}
     */
    @GetMapping("/currency/{currencyId}")
    public ResponseEntity<ExchangeRateDto> getRateByCurrencyId(@PathVariable Long currencyId) {
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);
        return ResponseEntity.ok(exchangeRateMapper.toDto(rate));
    }

    /**
     * Árfolyam valuta kód alapján
     *
     * GET /api/v1/exchange-rates/code/{currencyCode}
     */
    @GetMapping("/code/{currencyCode}")
    public ResponseEntity<ExchangeRateDto> getRateByCurrencyCode(@PathVariable String currencyCode) {
        ExchangeRate rate = exchangeRateService.getCurrentRateByCode(currencyCode);
        return ResponseEntity.ok(exchangeRateMapper.toDto(rate));
    }

    /**
     * Vételi árfolyam összeghez
     *
     * GET /api/v1/exchange-rates/buy-rate?currencyId=...&hufAmount=...
     */
    @GetMapping("/buy-rate")
    public ResponseEntity<BigDecimal> getBuyRateForAmount(
            @RequestParam Long currencyId,
            @RequestParam BigDecimal hufAmount) {
        BigDecimal rate = exchangeRateService.getBuyRateForAmount(currencyId, hufAmount);
        return ResponseEntity.ok(rate);
    }

    /**
     * Eladási árfolyam összeghez
     *
     * GET /api/v1/exchange-rates/sell-rate?currencyId=...&hufAmount=...
     */
    @GetMapping("/sell-rate")
    public ResponseEntity<BigDecimal> getSellRateForAmount(
            @RequestParam Long currencyId,
            @RequestParam BigDecimal hufAmount) {
        BigDecimal rate = exchangeRateService.getSellRateForAmount(currencyId, hufAmount);
        return ResponseEntity.ok(rate);
    }

    /**
     * Új árfolyam létrehozása
     *
     * POST /api/v1/exchange-rates
     *
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ExchangeRateDto> createExchangeRate(@Valid @RequestBody CreateExchangeRateDto dto) {
        ExchangeRate rate = exchangeRateService.createExchangeRate(exchangeRateMapper.toServiceRequest(dto));
        return ResponseEntity.status(HttpStatus.CREATED).body(exchangeRateMapper.toDto(rate));
    }

    /**
     * Árfolyam történet
     *
     * GET /api/v1/exchange-rates/history?currencyId=...&startDate=...&endDate=...
     */
    @GetMapping("/history")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<ExchangeRateDto>> getRateHistory(
            @RequestParam Long currencyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<ExchangeRate> rates = exchangeRateService.getRateHistory(currencyId, startDate, endDate);
        List<ExchangeRateDto> dtos = rates.stream()
                .map(exchangeRateMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }
}

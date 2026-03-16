package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.exchangerate.CreateExchangeRateDto;
import hu.puzzleir.valuta.dto.exchangerate.CurrentRateDto;
import hu.puzzleir.valuta.dto.exchangerate.ExchangeRateDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
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
     * Összes aktuális árfolyam (admin + pénztáros)
     *
     * GET /api/v1/exchange-rates
     * GET /api/v1/exchange-rates/current
     */
    @GetMapping({"", "/current"})
    public ResponseEntity<List<ExchangeRateDto>> getAllCurrentRates() {
        List<ExchangeRate> rates = exchangeRateService.getAllCurrentRates();
        List<ExchangeRateDto> dtos = rates.stream()
                .map(exchangeRateMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Aktuális árfolyamok a POS kliens számára (egyszerűsített DTO).
     *
     * GET /api/v1/exchange-rates/pos-current
     */
    @GetMapping("/pos-current")
    public ResponseEntity<List<CurrentRateDto>> getCurrentRatesForPos() {
        List<ExchangeRate> rates = exchangeRateService.getAllCurrentRates();
        List<CurrentRateDto> dtos = rates.stream()
                .map(exchangeRateMapper::toCurrentRateDto)
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
            @RequestParam(required = false) Long currencyId,
            @RequestParam(required = false) String currencyCode,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(name = "from", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(name = "to", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        LocalDate effectiveStartDate = startDate != null ? startDate : from;
        LocalDate effectiveEndDate = endDate != null ? endDate : to;

        if (effectiveStartDate == null || effectiveEndDate == null) {
            throw new ValidationException("A kezdő és záró dátum megadása kötelező.");
        }

        List<ExchangeRate> rates;
        if (currencyId != null) {
            rates = exchangeRateService.getRateHistory(currencyId, effectiveStartDate, effectiveEndDate);
        } else if (currencyCode != null && !currencyCode.isBlank()) {
            rates = exchangeRateService.getRateHistoryByCode(currencyCode.toUpperCase(), effectiveStartDate, effectiveEndDate);
        } else {
            throw new ValidationException("A currencyId vagy currencyCode paraméter megadása kötelező.");
        }

        List<ExchangeRateDto> dtos = rates.stream()
                .map(exchangeRateMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }
}

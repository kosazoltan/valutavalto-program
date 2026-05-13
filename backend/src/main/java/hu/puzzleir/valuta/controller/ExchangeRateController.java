package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.exchangerate.CreateExchangeRateDto;
import hu.puzzleir.valuta.dto.exchangerate.CurrentRateDto;
import hu.puzzleir.valuta.dto.exchangerate.ExchangeRateDto;
import hu.puzzleir.valuta.dto.rate.ParsedRateFile;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.mapper.ExchangeRateMapper;
import hu.puzzleir.valuta.service.ExchangeRateService;
import hu.puzzleir.valuta.service.RateFileParserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
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

    private static final String RATE_READ_ROLES =
            "hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')";
    private static final String RATE_WRITE_ROLES =
            "hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')";

    private final ExchangeRateService exchangeRateService;
    private final ExchangeRateMapper exchangeRateMapper;
    private final RateFileParserService rateFileParserService;

    /**
     * Összes aktuális árfolyam (admin + pénztáros)
     *
     * GET /api/v1/exchange-rates
     * GET /api/v1/exchange-rates/current
     */
    @GetMapping({"", "/current"})
    @PreAuthorize(RATE_READ_ROLES)
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
    @PreAuthorize(RATE_READ_ROLES)
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
    @PreAuthorize(RATE_READ_ROLES)
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
    @PreAuthorize(RATE_READ_ROLES)
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
    @PreAuthorize(RATE_READ_ROLES)
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
    @PreAuthorize(RATE_READ_ROLES)
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
    @PreAuthorize(RATE_WRITE_ROLES)
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
    @PreAuthorize(RATE_WRITE_ROLES)
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

    /**
     * Legacy GETARF árfolyamfájl feltöltése és feldolgozása.
     *
     * Csak feldolgozza és visszaadja a parse-olt adatokat (nem importálja automatikusan).
     *
     * POST /api/v1/exchange-rates/upload-rate-file
     */
    @PostMapping("/upload-rate-file")
    @PreAuthorize(RATE_WRITE_ROLES)
    public ResponseEntity<ParsedRateFile> uploadRateFile(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            throw new ValidationException("Az árfolyamfájl nem lehet üres!");
        }

        try {
            byte[] content = file.getBytes();
            ParsedRateFile parsed = rateFileParserService.parseRateFile(content);

            if (parsed.getRates().isEmpty()) {
                throw new ValidationException("Az árfolyamfájl nem tartalmaz érvényes árfolyamokat!");
            }

            return ResponseEntity.ok(parsed);
        } catch (IOException e) {
            throw new ValidationException("Hiba az árfolyamfájl olvasásakor: " + e.getMessage());
        }
    }

    /**
     * Legacy GETARF árfolyamfájl feltöltése és azonnali importálása.
     *
     * Feldolgozza a fájlt, majd az összes érvényes árfolyamot importálja a rendszerbe.
     *
     * POST /api/v1/exchange-rates/import-rate-file
     */
    @PostMapping("/import-rate-file")
    @PreAuthorize(RATE_WRITE_ROLES)
    public ResponseEntity<List<ExchangeRateDto>> importRateFile(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            throw new ValidationException("Az árfolyamfájl nem lehet üres!");
        }

        try {
            byte[] content = file.getBytes();
            ParsedRateFile parsed = rateFileParserService.parseRateFile(content);

            if (parsed.getRates().isEmpty()) {
                throw new ValidationException("Az árfolyamfájl nem tartalmaz érvényes árfolyamokat!");
            }

            List<ExchangeRate> imported = exchangeRateService.importRatesFromParsedFile(parsed);
            List<ExchangeRateDto> dtos = imported.stream()
                    .map(exchangeRateMapper::toDto)
                    .collect(Collectors.toList());

            return ResponseEntity.status(HttpStatus.CREATED).body(dtos);
        } catch (IOException e) {
            throw new ValidationException("Hiba az árfolyamfájl olvasásakor: " + e.getMessage());
        }
    }
}

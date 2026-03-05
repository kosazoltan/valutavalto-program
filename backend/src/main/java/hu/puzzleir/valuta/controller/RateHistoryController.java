package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ratehistory.RateHistoryDto;
import hu.puzzleir.valuta.service.RateHistoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Árfolyam történet controller.
 *
 * GET /api/v1/rate-history?currency=&from=&to=
 * GET /api/v1/rate-history/at-date?currency=&date=
 */
@RestController
@RequestMapping("/api/v1/rate-history")
@RequiredArgsConstructor
public class RateHistoryController {

    private final RateHistoryService rateHistoryService;

    /**
     * Árfolyam változások lekérdezése időszakra
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<RateHistoryDto>> getRateHistory(
            @RequestParam String currency,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(rateHistoryService.getRateChanges(currency, from, to));
    }

    /**
     * Adott pillanatban érvényes árfolyam
     */
    @GetMapping("/at-date")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<RateHistoryDto> getRateAtDate(
            @RequestParam String currency,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime date) {
        return ResponseEntity.ok(rateHistoryService.getRateAtDate(currency, date));
    }
}

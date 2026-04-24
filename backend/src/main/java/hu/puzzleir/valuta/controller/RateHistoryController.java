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
     * Árfolyam változások lekérdezése időszakra.
     * Fix 2026-04-24 (Issue #184): params opcionálisak, default utolsó 30 nap + minden valuta.
     * AI review fix (Sourcery PR #185): egyetlen LocalDate.now() hasznalata (midnight race ellen)
     * + from/to swap ha a kliens inverz intervallumot kuld.
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<RateHistoryDto>> getRateHistory(
            @RequestParam(required = false) String currency,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        LocalDate now = LocalDate.now();
        LocalDate effectiveFrom = (from != null) ? from : now.minusDays(30);
        LocalDate effectiveTo = (to != null) ? to : now;

        // AI review (Codex PR #186 P2): swap CSAK ha MINDKETTO explicit bounded.
        // Ha csak egyik default, NE modositsuk silent-ben a user intent-et.
        if (from != null && to != null && effectiveFrom.isAfter(effectiveTo)) {
            LocalDate tmp = effectiveFrom;
            effectiveFrom = effectiveTo;
            effectiveTo = tmp;
        }

        return ResponseEntity.ok(rateHistoryService.getRateChanges(currency, effectiveFrom, effectiveTo));
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

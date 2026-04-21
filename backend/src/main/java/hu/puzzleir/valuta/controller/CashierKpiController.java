package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.dashboard.CashierKpiSummaryDto;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.service.CashierKpiService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * B2: Penztaros KPI dashboard controller.
 *
 * Csak SUPERVISOR/MANAGER/ADMIN/FOERTEKTAR/UGYVEZETO latja — adategyeztetes erzekeny.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
@RestController
@RequestMapping("/api/v1/cashier-kpis")
@RequiredArgsConstructor
public class CashierKpiController {

    private final CashierKpiService service;

    /**
     * Max 1 eves idotartomany - DoS + teljesitmenyi okokbol (sok tranzakcio, sok penztaros).
     */
    private static final long MAX_RANGE_DAYS = 366;

    /**
     * Osszesito penztaros KPI adott idotartomanyra (pl. ma, ez a honap, etc.).
     *
     * GET /api/v1/cashier-kpis?dateFrom=2026-04-01&dateTo=2026-04-21
     */
    @GetMapping
    public ResponseEntity<CashierKpiSummaryDto> getKpis(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateFrom,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateTo) {
        validateDateRange(dateFrom, dateTo);
        return ResponseEntity.ok(service.getKpis(dateFrom, dateTo));
    }

    /**
     * Input validacio: dateFrom <= dateTo es max 1 ev.
     */
    private void validateDateRange(LocalDate dateFrom, LocalDate dateTo) {
        if (dateFrom.isAfter(dateTo)) {
            throw new ValidationException("dateFrom nem lehet keso dateTo-nal: " + dateFrom + " > " + dateTo);
        }
        long days = ChronoUnit.DAYS.between(dateFrom, dateTo);
        if (days > MAX_RANGE_DAYS) {
            throw new ValidationException("Maximum " + MAX_RANGE_DAYS + " nap kerheto egyszerre (jelenleg: " + days + " nap)");
        }
        if (dateFrom.isAfter(LocalDate.now().plusDays(1))) {
            throw new ValidationException("dateFrom nem lehet a jovoben");
        }
    }
}
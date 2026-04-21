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
     * Maximum intervallum SIZE - ChronoUnit.DAYS.between exclusive,
     * ezert 366 = max 367 inclusive day (szokoev + 1 extra). DoS + teljesitmenyi korlat.
     *
     * Peldak:
     *  - dateFrom=2026-01-01, dateTo=2026-01-01 -> days=0 (engedjen, 1 napos keres)
     *  - dateFrom=2026-01-01, dateTo=2027-01-01 -> days=365 (engedjen, 1 ev)
     *  - dateFrom=2026-01-01, dateTo=2027-01-02 -> days=366 (engedjen, 367 nap inclusive)
     *  - dateFrom=2026-01-01, dateTo=2027-01-03 -> days=367 -> VALIDATION ERROR
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
            throw new ValidationException("Maximum " + (MAX_RANGE_DAYS + 1) + " napos (inclusive) intervallum engedely. Jelenleg kert: " + (days + 1) + " nap.");
        }
        if (dateFrom.isAfter(LocalDate.now().plusDays(1))) {
            throw new ValidationException("dateFrom nem lehet a jovoben");
        }
    }
}
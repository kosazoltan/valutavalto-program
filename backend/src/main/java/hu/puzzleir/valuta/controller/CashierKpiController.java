package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.dashboard.CashierKpiSummaryDto;
import hu.puzzleir.valuta.service.CashierKpiService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

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
     * Osszesito penztaros KPI adott idotartomanyra (pl. ma, este a hon, etc.).
     *
     * GET /api/v1/cashier-kpis?dateFrom=2026-04-01&dateTo=2026-04-21
     */
    @GetMapping
    public ResponseEntity<CashierKpiSummaryDto> getKpis(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateFrom,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateTo) {
        return ResponseEntity.ok(service.getKpis(dateFrom, dateTo));
    }
}
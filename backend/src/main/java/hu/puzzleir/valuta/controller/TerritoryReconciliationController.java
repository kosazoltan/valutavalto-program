package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.revaluation.TerritoryReconciliationDto;
import hu.puzzleir.valuta.service.revaluation.RevaluationAllocationService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;

/**
 * Területi reconciliation + értéktári átértékelés-lecsorgatás riport endpoint.
 */
@RestController
@RequestMapping("/api/v1/reports/territory-reconciliation")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER','ADMIN','COMPLIANCE')")
public class TerritoryReconciliationController {

    private final RevaluationAllocationService service;

    /**
     * GET /api/v1/reports/territory-reconciliation?territoryId=20&yearMonth=2026-05
     * vagy explicit from/to-val.
     */
    @GetMapping
    public ResponseEntity<TerritoryReconciliationDto> get(
            @RequestParam Integer territoryId,
            @RequestParam(required = false) String yearMonth,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {

        LocalDate fromDate = from;
        LocalDate toDate = to;
        if (yearMonth != null && !yearMonth.isBlank()) {
            YearMonth ym = YearMonth.parse(yearMonth);
            fromDate = ym.atDay(1);
            toDate = ym.atEndOfMonth();
        }
        if (fromDate == null || toDate == null) {
            YearMonth ym = YearMonth.now();
            fromDate = ym.atDay(1);
            toDate = ym.atEndOfMonth();
        }
        return ResponseEntity.ok(service.reconcileTerritory(territoryId, fromDate, toDate));
    }
}

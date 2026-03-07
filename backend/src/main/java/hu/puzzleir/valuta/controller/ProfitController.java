package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.ProfitCalculationService;
import hu.puzzleir.valuta.service.WacService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Haszon számítás controller.
 *
 * Endpointok (hagyományos):
 * - GET /daily?branchId=&date=               → napi haszon
 * - GET /monthly?branchId=&month=            → havi haszon
 * - GET /company?companyId=&month=           → cég szintű haszon
 *
 * WAC-alapú endpointok:
 * - GET /branch/{branchId}?from=&to=         → pénztár WAC haszon
 * - GET /territory/{territoryId}?from=&to=   → területi WAC haszon
 * - GET /summary?from=&to=                   → összesítő WAC haszon
 */
@RestController
@RequestMapping("/api/v1/profit")
@RequiredArgsConstructor
public class ProfitController {

    private final ProfitCalculationService service;
    private final WacService wacService;

    // ============ HAGYOMÁNYOS PROFIT ENDPOINTOK ============

    @GetMapping("/daily")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ProfitCalculationService.ProfitReport> daily(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(service.calculateDailyProfit(branchId, date));
    }

    @GetMapping("/monthly")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<ProfitCalculationService.ProfitReport> monthly(
            @RequestParam UUID branchId,
            @RequestParam String month) {
        return ResponseEntity.ok(service.calculateMonthlyProfit(branchId, month));
    }

    @GetMapping("/company")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ProfitCalculationService.ProfitReport> company(
            @RequestParam UUID companyId,
            @RequestParam String month) {
        return ResponseEntity.ok(service.calculateCompanyProfit(companyId, month));
    }

    // ============ WAC-ALAPÚ PROFIT ENDPOINTOK ============

    /**
     * Pénztár szintű WAC haszon.
     */
    @GetMapping("/branch/{branchId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'SUPERVISOR')")
    public ResponseEntity<WacService.ProfitSummary> branchProfit(
            @PathVariable UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A kezdő dátum nem lehet későbbi mint a záró dátum!");
        }
        return ResponseEntity.ok(wacService.getBranchProfitSummary(branchId, from, to));
    }

    /**
     * Területi szintű WAC haszon.
     */
    @GetMapping("/territory/{territoryId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<WacService.ProfitSummary> territoryProfit(
            @PathVariable Integer territoryId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A kezdő dátum nem lehet későbbi mint a záró dátum!");
        }
        return ResponseEntity.ok(wacService.getTerritoryProfitSummary(territoryId, from, to));
    }

    /**
     * Cég szintű összesítő WAC haszon.
     */
    @GetMapping("/summary")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<WacService.ProfitSummary> summaryProfit(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        if (from != null && to != null && from.isAfter(to)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A kezdő dátum nem lehet későbbi mint a záró dátum!");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return ResponseEntity.ok(wacService.getCompanyProfitSummary(companyId, from, to));
    }
}

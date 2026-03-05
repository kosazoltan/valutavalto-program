package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.ProfitCalculationService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Haszon számítás controller.
 *
 * Endpointok:
 * - GET /daily?branchId=&date=      → napi haszon
 * - GET /monthly?branchId=&month=   → havi haszon
 * - GET /company?companyId=&month=  → cég szintű haszon
 */
@RestController
@RequestMapping("/api/v1/profit")
@RequiredArgsConstructor
public class ProfitController {

    private final ProfitCalculationService service;

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
}

package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * Riport controller
 *
 * Legacy: Napi zárás riportok, forgalmi kimutatások
 */
@RestController
@RequestMapping("/api/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /**
     * Napi zárás riport
     *
     * GET /api/v1/reports/daily-closing?date=2024-01-15
     */
    @GetMapping("/daily-closing")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.DailyClosingReport> getDailyClosingReport(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate reportDate = date != null ? date : LocalDate.now();
        ReportService.DailyClosingReport report = reportService.generateDailyClosingReport(reportDate);
        return ResponseEntity.ok(report);
    }

    /**
     * Időszaki forgalmi kimutatás
     *
     * GET /api/v1/reports/period?startDate=...&endDate=...
     */
    @GetMapping("/period")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.PeriodReport> getPeriodReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.PeriodReport report = reportService.generatePeriodReport(startDate, endDate);
        return ResponseEntity.ok(report);
    }

    /**
     * Pénztáros teljesítmény riport
     *
     * GET /api/v1/reports/worker/{workerId}?startDate=...&endDate=...
     */
    @GetMapping("/worker/{workerId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.WorkerPerformanceReport> getWorkerPerformanceReport(
            @PathVariable Long workerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.WorkerPerformanceReport report =
                reportService.generateWorkerPerformanceReport(workerId, startDate, endDate);
        return ResponseEntity.ok(report);
    }

    /**
     * Valutánkénti forgalmi kimutatás
     *
     * GET /api/v1/reports/currency/{currencyId}?startDate=...&endDate=...
     */
    @GetMapping("/currency/{currencyId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.CurrencyReport> getCurrencyReport(
            @PathVariable Long currencyId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.CurrencyReport report =
                reportService.generateCurrencyReport(currencyId, startDate, endDate);
        return ResponseEntity.ok(report);
    }

    /**
     * Kassza állapot riport (pillanat állás)
     *
     * GET /api/v1/reports/cash-status
     */
    @GetMapping("/cash-status")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.CashStatusReport> getCashStatusReport() {
        ReportService.CashStatusReport report = reportService.generateCashStatusReport();
        return ResponseEntity.ok(report);
    }

    /**
     * Mai napi összesítő (dashboard)
     *
     * GET /api/v1/reports/today-summary
     */
    @GetMapping("/today-summary")
    public ResponseEntity<ReportService.DailyClosingReport> getTodaySummary() {
        ReportService.DailyClosingReport report = reportService.generateDailyClosingReport(LocalDate.now());
        return ResponseEntity.ok(report);
    }
}

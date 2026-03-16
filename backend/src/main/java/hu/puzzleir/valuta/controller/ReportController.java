package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.ReportExportService;
import hu.puzzleir.valuta.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
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
    private final ReportExportService reportExportService;

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

    /**
     * Havi forgalmi kimutatás
     *
     * GET /api/v1/reports/monthly-turnover?year=2024&month=1
     */
    @GetMapping("/monthly-turnover")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.MonthlyTurnoverReport> getMonthlyTurnoverReport(
            @RequestParam Integer year,
            @RequestParam Integer month) {
        ReportService.MonthlyTurnoverReport report = reportService.generateMonthlyTurnoverReport(year, month);
        return ResponseEntity.ok(report);
    }

    /**
     * Átadás-átvétel összesítő riport
     *
     * GET /api/v1/reports/transfers?startDate=...&endDate=...
     */
    @GetMapping("/transfers")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.TransferReport> getTransferReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.TransferReport report = reportService.generateTransferReport(startDate, endDate);
        return ResponseEntity.ok(report);
    }

    /**
     * Kezelési díj összesítő riport
     *
     * GET /api/v1/reports/handling-fees?startDate=...&endDate=...
     */
    @GetMapping("/handling-fees")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReportService.HandlingFeeReport> getHandlingFeeReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.HandlingFeeReport report = reportService.generateHandlingFeeReport(startDate, endDate);
        return ResponseEntity.ok(report);
    }

    // ============ CSV EXPORT ENDPOINTOK ============

    /**
     * Pénztáros teljesítmény riport CSV export
     *
     * GET /api/v1/reports/worker/{workerId}/csv?startDate=...&endDate=...
     */
    @GetMapping("/worker/{workerId}/csv")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportWorkerPerformanceCsv(
            @PathVariable Long workerId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.WorkerPerformanceReport report =
                reportService.generateWorkerPerformanceReport(workerId, startDate, endDate);
        byte[] bom = reportExportService.getBom();
        byte[] csv = reportExportService.exportWorkerPerformanceCsv(report).getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] body = concat(bom, csv);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"penztaros-teljesitmeny-" + workerId + ".csv\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(body);
    }

    /**
     * Kezelési díj riport CSV export
     *
     * GET /api/v1/reports/handling-fees/csv?startDate=...&endDate=...
     */
    @GetMapping("/handling-fees/csv")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportHandlingFeeCsv(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.HandlingFeeReport report = reportService.generateHandlingFeeReport(startDate, endDate);
        byte[] bom = reportExportService.getBom();
        byte[] csv = reportExportService.exportHandlingFeeCsv(report).getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] body = concat(bom, csv);
        String filename = "kezelesi-dij-" + startDate + "-" + endDate + ".csv";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(body);
    }

    /**
     * Havi forgalmi kimutatás CSV export
     *
     * GET /api/v1/reports/monthly-turnover/csv?year=2024&month=1
     */
    @GetMapping("/monthly-turnover/csv")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportMonthlyTurnoverCsv(
            @RequestParam Integer year,
            @RequestParam Integer month) {
        ReportService.MonthlyTurnoverReport report = reportService.generateMonthlyTurnoverReport(year, month);
        byte[] bom = reportExportService.getBom();
        byte[] csv = reportExportService.exportMonthlyTurnoverCsv(report).getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] body = concat(bom, csv);
        String filename = "havi-forgalom-" + year + "-" + String.format("%02d", month) + ".csv";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(body);
    }

    /**
     * Időszaki forgalmi kimutatás CSV export
     *
     * GET /api/v1/reports/period/csv?startDate=...&endDate=...
     */
    @GetMapping("/period/csv")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> exportPeriodReportCsv(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        ReportService.PeriodReport report = reportService.generatePeriodReport(startDate, endDate);
        byte[] bom = reportExportService.getBom();
        byte[] csv = reportExportService.exportPeriodReportCsv(report).getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] body = concat(bom, csv);
        String filename = "idoszaki-forgalom-" + startDate + "-" + endDate + ".csv";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(body);
    }

    private static byte[] concat(byte[] a, byte[] b) {
        byte[] result = new byte[a.length + b.length];
        System.arraycopy(a, 0, result, 0, a.length);
        System.arraycopy(b, 0, result, a.length, b.length);
        return result;
    }
}

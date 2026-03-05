package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.CentralReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.YearMonth;

/**
 * Központi riport controller — locserver.
 * Napi/heti/havi konszolidált riportok CSV formátumban.
 */
@RestController
@RequestMapping("/api/v1/central-reports")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class CentralReportController {

    private final CentralReportService centralReportService;

    /**
     * Napi konszolidált riport.
     * GET /api/v1/central-reports/daily?date=2026-03-06
     */
    @GetMapping("/daily")
    public ResponseEntity<byte[]> getDailyReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] csv = centralReportService.generateDailyConsolidation(date);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=napi_riport_" + date + ".csv")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv);
    }

    /**
     * Heti riport.
     * GET /api/v1/central-reports/weekly?weekStart=2026-03-02
     */
    @GetMapping("/weekly")
    public ResponseEntity<byte[]> getWeeklyReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        byte[] csv = centralReportService.generateWeeklyReport(weekStart);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=heti_riport_" + weekStart + ".csv")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv);
    }

    /**
     * Havi riport.
     * GET /api/v1/central-reports/monthly?month=2026-03
     */
    @GetMapping("/monthly")
    public ResponseEntity<byte[]> getMonthlyReport(
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        byte[] csv = centralReportService.generateMonthlyReport(month);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=havi_riport_" + month + ".csv")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv);
    }
}

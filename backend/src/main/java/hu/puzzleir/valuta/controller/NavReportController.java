package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.nav.NavReportDto;
import hu.puzzleir.valuta.dto.nav.NavReportableTransactionDto;
import hu.puzzleir.valuta.service.NavReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * NAV adatszolgáltatás controller.
 *
 * 2M+ Ft tranzakciók jelentése a Nemzeti Adó- és Vámhivatal felé.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/nav-reports")
@RequiredArgsConstructor
public class NavReportController {

    private final NavReportService navReportService;

    /**
     * Napi NAV riport.
     * GET /api/v1/nav-reports/daily?date=
     */
    @GetMapping("/daily")
    public ResponseEntity<NavReportDto> getDailyReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(navReportService.generateNavReport(date));
    }

    /**
     * CSV export.
     * GET /api/v1/nav-reports/csv?date=
     */
    @GetMapping("/csv")
    public ResponseEntity<byte[]> exportCsv(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] csv = navReportService.exportNavCsv(date);
        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION,
                "attachment; filename=nav_report_" + date + ".csv")
            .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
            .body(csv);
    }

    /**
     * Jelenthető tranzakciók listája.
     * GET /api/v1/nav-reports/reportable?date=
     */
    @GetMapping("/reportable")
    public ResponseEntity<List<NavReportableTransactionDto>> getReportableTransactions(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(navReportService.getReportableTransactions(date));
    }
}

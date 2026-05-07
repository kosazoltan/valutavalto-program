package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.darius.DariusDailyReportDto;
import hu.puzzleir.valuta.dto.darius.DariusMonthlyDto;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.service.DariusReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Darius/Raiffeisen napi jelentés REST controller.
 *
 * Jogosultság: MAIN_TREASURY, COMPLIANCE_OFFICER, SYSTEM_ADMIN
 * A pénztárosok és értéktárosok NEM látják a Darius jelentéseket.
 */
@RestController
@RequestMapping({"/api/v1/darius", "/api/darius"})
@RequiredArgsConstructor
public class DariusReportController {

    private final DariusReportService dariusReportService;

    // === Generálás ===

    /**
     * Napi jelentés generálása.
     * Összesíti az adott nap tranzakcióit valutánként és irodánként.
     */
    @PostMapping("/generate")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN')")
    public ResponseEntity<DariusDailyReportDto> generate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(dariusReportService.generateDailyReport(date));
    }

    // === Jóváhagyás (4-eyes) ===

    @PostMapping("/{reportId}/approve")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY')")
    public ResponseEntity<DariusDailyReportDto> approve(@PathVariable UUID reportId) {
        return ResponseEntity.ok(dariusReportService.approveReport(reportId));
    }

    // === Beküldés ===

    @PostMapping("/{reportId}/submit")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN')")
    public ResponseEntity<DariusDailyReportDto> submit(@PathVariable UUID reportId) {
        DariusDailyReportDto report = dariusReportService.submitReport(reportId);
        return ResponseEntity.status(statusForReport(report)).body(report);
    }

    // === Acknowledgment ===

    @PostMapping("/{reportId}/acknowledge")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'SYSTEM_ADMIN')")
    public ResponseEntity<DariusDailyReportDto> acknowledge(
            @PathVariable UUID reportId,
            @RequestParam String ackReference) {
        return ResponseEntity.ok(dariusReportService.acknowledgeReport(reportId, ackReference));
    }

    // === Retry ===

    @PostMapping("/retry-failed")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'SYSTEM_ADMIN')")
    public ResponseEntity<List<DariusDailyReportDto>> retryFailed() {
        List<DariusDailyReportDto> reports = dariusReportService.retryFailedReports();
        boolean anyFailed = reports.stream().anyMatch(this::isFailedReport);
        return ResponseEntity.status(anyFailed ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.OK).body(reports);
    }

    // === Lekérdezések ===

    @GetMapping("/{reportId}")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<DariusDailyReportDto> getById(@PathVariable UUID reportId) {
        return ResponseEntity.ok(dariusReportService.getReport(reportId));
    }

    @GetMapping("/by-date")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<DariusDailyReportDto> getByDate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(dariusReportService.getReportByDate(date));
    }

    @GetMapping("/range")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<List<DariusDailyReportDto>> getByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(dariusReportService.getReportsByDateRange(startDate, endDate));
    }

    // === Havi összesítő ===

    @GetMapping("/monthly")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'COMPLIANCE_OFFICER', 'SYSTEM_ADMIN')")
    public ResponseEntity<DariusMonthlyDto> getMonthly(
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(dariusReportService.getMonthlyReport(year, month));
    }

    // === Hiányzó napok ===

    @GetMapping("/missing-dates")
    @PreAuthorize("hasAnyAuthority('DARIUS_REPORT_RUN', 'MAIN_TREASURY', 'SYSTEM_ADMIN')")
    public ResponseEntity<List<LocalDate>> getMissingDates(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(dariusReportService.findMissingDates(startDate, endDate));
    }

    private HttpStatus statusForReport(DariusDailyReportDto report) {
        return isFailedReport(report) ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.OK;
    }

    private boolean isFailedReport(DariusDailyReportDto report) {
        return report != null && DariusReportStatus.FAILED.name().equals(report.getStatus());
    }
}

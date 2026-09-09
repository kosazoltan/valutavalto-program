package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.darius.DariusDailyReportDto;
import hu.puzzleir.valuta.dto.darius.DariusImportFile;
import hu.puzzleir.valuta.dto.darius.DariusImportReadinessDto;
import hu.puzzleir.valuta.dto.darius.DariusMonthlyDto;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.service.DariusReportService;
import hu.puzzleir.valuta.service.darius.DariusImportFileService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Darius/Raiffeisen napi jelentés REST controller.
 *
 * Jogosultság: FOERTEKTAR, ADMIN; compliance-olvasásra BELSO_ELLENOR.
 * FK-109 FR-5/FR-6: a nem seedelt, holt authority-nevek (DARIUS_REPORT_RUN,
 * MAIN_TREASURY, SYSTEM_ADMIN) eltávolítva — authority-only principal elutasítandó;
 * a COMPLIANCE_OFFICER authority az olvasó endpointokon megmarad.
 * A pénztárosok és értéktárosok NEM látják a Darius jelentéseket.
 */
@RestController
@RequestMapping({"/api/v1/darius", "/api/darius"})
@RequiredArgsConstructor
public class DariusReportController {

    private final DariusReportService dariusReportService;
    private final DariusImportFileService dariusImportFileService;

    // === Generálás ===

    /**
     * Napi jelentés generálása.
     * Összesíti az adott nap tranzakcióit valutánként és irodánként.
     */
    @PostMapping("/generate")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusDailyReportDto> generate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(dariusReportService.generateDailyReport(date));
    }

    // === Jóváhagyás (4-eyes) ===

    @PostMapping("/{reportId}/approve")
    @PreAuthorize("hasAnyRole('FOERTEKTAR')")
    public ResponseEntity<DariusDailyReportDto> approve(@PathVariable UUID reportId) {
        return ResponseEntity.ok(dariusReportService.approveReport(reportId));
    }

    // === Beküldés ===

    @PostMapping("/{reportId}/submit")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusDailyReportDto> submit(@PathVariable UUID reportId) {
        DariusDailyReportDto report = dariusReportService.submitReport(reportId);
        return ResponseEntity.status(statusForReport(report)).body(report);
    }

    // === Acknowledgment ===

    @PostMapping("/{reportId}/acknowledge")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<DariusDailyReportDto> acknowledge(
            @PathVariable UUID reportId,
            @RequestParam String ackReference) {
        return ResponseEntity.ok(dariusReportService.acknowledgeReport(reportId, ackReference));
    }

    // === Retry ===

    @PostMapping("/retry-failed")
    @PreAuthorize("hasAnyRole('ADMIN')")
    public ResponseEntity<List<DariusDailyReportDto>> retryFailed() {
        List<DariusDailyReportDto> reports = dariusReportService.retryFailedReports();
        boolean anyFailed = reports.stream().anyMatch(this::isFailedReport);
        return ResponseEntity.status(anyFailed ? HttpStatus.SERVICE_UNAVAILABLE : HttpStatus.OK).body(reports);
    }

    // === Lekérdezések ===

    @GetMapping("/{reportId}")
    @PreAuthorize("hasAnyAuthority('COMPLIANCE_OFFICER') or hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<DariusDailyReportDto> getById(@PathVariable UUID reportId) {
        return ResponseEntity.ok(dariusReportService.getReport(reportId));
    }

    @GetMapping("/by-date")
    @PreAuthorize("hasAnyAuthority('COMPLIANCE_OFFICER') or hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<DariusDailyReportDto> getByDate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(dariusReportService.getReportByDate(date));
    }

    @GetMapping("/range")
    @PreAuthorize("hasAnyAuthority('COMPLIANCE_OFFICER') or hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<List<DariusDailyReportDto>> getByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(dariusReportService.getReportsByDateRange(startDate, endDate));
    }

    // === FS-15: Raiffeisen importfájl-letöltés ===

    @GetMapping("/import-file")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<byte[]> downloadImportFile(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(defaultValue = "0") int erteknap) {
        DariusImportFile file = dariusImportFileService.generateImportFile(date, erteknap);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + file.fileName() + "\"")
                .header("X-Darius-Skipped-Branches", String.join(",", file.skippedBranches()))
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(file.content());
    }

    /** FS-15: importfájl-készenlét ellenőrzése exportkísérlet nélkül. */
    @GetMapping("/import-readiness")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<DariusImportReadinessDto> importReadiness() {
        return ResponseEntity.ok(dariusImportFileService.importReadiness());
    }

    // === Havi összesítő ===

    @GetMapping("/monthly")
    @PreAuthorize("hasAnyAuthority('COMPLIANCE_OFFICER') or hasAnyRole('FOERTEKTAR', 'BELSO_ELLENOR', 'ADMIN')")
    public ResponseEntity<DariusMonthlyDto> getMonthly(
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(dariusReportService.getMonthlyReport(year, month));
    }

    // === Hiányzó napok ===

    @GetMapping("/missing-dates")
    @PreAuthorize("hasAnyRole('FOERTEKTAR', 'ADMIN')")
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

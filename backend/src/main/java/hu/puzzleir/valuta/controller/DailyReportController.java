package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.DailyReportDto;
import hu.puzzleir.valuta.dto.treasury.SubmissionStatusDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.DailyReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Napi jelentés controller.
 *
 * Legacy: napijel.dll — napi forgalmi adatok összesítése és beküldése.
 */
@RestController
@RequestMapping("/api/v1/reports/daily")
@RequiredArgsConstructor
public class DailyReportController {

    private final DailyReportService dailyReportService;

    @GetMapping("/{branchId}/{date}")
    public ResponseEntity<DailyReportDto> getReport(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(dailyReportService.getReport(branchId, date));
    }

    @PostMapping("/{branchId}/generate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailyReportDto> generateReport(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate reportDate = date != null ? date : LocalDate.now();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(dailyReportService.generateReport(branchId, reportDate));
    }

    @PostMapping("/{reportId}/submit")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<DailyReportDto> submitReport(
            @PathVariable Long reportId,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(dailyReportService.submitReport(reportId, workerId));
    }

    @GetMapping("/submission-status")
    public ResponseEntity<List<SubmissionStatusDto>> getSubmissionStatus(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate reportDate = date != null ? date : LocalDate.now();
        return ResponseEntity.ok(dailyReportService.getSubmissionStatus(reportDate));
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}

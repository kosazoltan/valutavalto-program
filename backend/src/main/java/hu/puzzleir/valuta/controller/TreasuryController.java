package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.treasury.*;
import hu.puzzleir.valuta.service.TreasuryDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Központi összesítő (Treasury Dashboard) controller.
 *
 * Legacy: SZERVER — bankforg.dll, keszletdisp.dll, forgalomdisp.dll, zarasctrl.dll
 */
@RestController
@RequestMapping("/api/v1/treasury")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class TreasuryController {

    private final TreasuryDashboardService treasuryDashboardService;

    @GetMapping("/dashboard")
    public ResponseEntity<TreasuryDashboardDto> getDashboard() {
        return ResponseEntity.ok(treasuryDashboardService.getCompanyWideSummary());
    }

    @GetMapping("/branch-comparison")
    public ResponseEntity<List<BranchComparisonDto>> getBranchComparison() {
        return ResponseEntity.ok(treasuryDashboardService.getBranchComparison());
    }

    @GetMapping("/bank-flow")
    public ResponseEntity<List<BankFlowDto>> getBankFlow(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return ResponseEntity.ok(treasuryDashboardService.getBankFlowSummary(startDate, endDate));
    }

    @GetMapping("/submission-status")
    public ResponseEntity<List<SubmissionStatusDto>> getSubmissionStatus() {
        return ResponseEntity.ok(treasuryDashboardService.getSubmissionStatus());
    }
}

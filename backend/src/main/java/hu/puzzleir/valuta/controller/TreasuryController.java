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
// FK-037 (2026-06-20): a kozponti ertektari szerepkorok (FOERTEKTAR/UGYVEZETO) is
// jogosultak a cegszintu treasury-osszesitok OLVASASARA. Korabban csak MANAGER/ADMIN,
// igy a Foertektaros/Ugyvezeto 403-at kapott a sajat dashboardjan (regresszio: a
// frontend rakototte a dashboardot ezekre, de a backend role-lista nem kovette).
// A controller MINDEN vegpontja read-only GET, ezert osztaly-szinten bovitheto.
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
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

    @GetMapping("/branch-group-summary")
    public ResponseEntity<List<TreasuryAggregateDto>> getBranchGroupSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(treasuryDashboardService.getBranchGroupSummary(date));
    }

    @GetMapping("/company-summary")
    public ResponseEntity<List<TreasuryAggregateDto>> getCompanySummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(treasuryDashboardService.getCompanySummary(date));
    }

    /**
     * Ügyfélforgalom összesítő — irodánként, valutanemenként eladott/vett.
     * Legacy: unit5.pas SUMUGYFELFORGALOM tábla nézete.
     * GET /api/v1/treasury/customer-turnover?date=2026-04-07
     */
    @GetMapping("/customer-turnover")
    public ResponseEntity<List<CustomerTurnoverDto>> getCustomerTurnover(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(treasuryDashboardService.getCustomerTurnover(date));
    }

    /**
     * Bankforgalom összesítő — valutanemenként felvett/kifizetett KP, cégenként.
     * Legacy: unit5.pas SUMBANKFORGALOM tábla nézete.
     * GET /api/v1/treasury/bank-turnover?date=2026-04-07
     */
    @GetMapping("/bank-turnover")
    public ResponseEntity<List<BankTurnoverDto>> getBankTurnover(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(treasuryDashboardService.getBankTurnover(date));
    }
}

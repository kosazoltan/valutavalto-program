package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.HrkMonthlyClosingService;
import hu.puzzleir.valuta.service.HrkMonthlyClosingService.HrkMonthlySummary;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * HRK havi zárás REST API.
 *
 * Legacy: HRKZARO — havi készletmozgás összesítés.
 */
@RestController
@RequestMapping("/api/v1/hrk/monthly")
@RequiredArgsConstructor
@Tag(name = "HRK Havi Zárás", description = "HRK készletmozgás havi összesítés és zárás")
public class HrkMonthlyClosingController {

    private final HrkMonthlyClosingService hrkMonthlyClosingService;

    @GetMapping("/summary")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "HRK havi összesítő lekérdezés")
    public ResponseEntity<HrkMonthlySummary> getSummary(
            @RequestParam String yearMonth) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return ResponseEntity.ok(hrkMonthlyClosingService.getMonthlySummary(branchId, yearMonth));
    }

    @PostMapping("/close")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "HRK havi zárás végrehajtása")
    public ResponseEntity<HrkMonthlySummary> closeMonth(
            @RequestParam String yearMonth) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return ResponseEntity.ok(hrkMonthlyClosingService.closeMonth(branchId, yearMonth));
    }
}

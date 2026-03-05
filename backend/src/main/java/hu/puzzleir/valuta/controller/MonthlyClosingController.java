package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.MonthlyClosingSummary;
import hu.puzzleir.valuta.service.MonthlyClosingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Havi zárás controller.
 *
 * Legacy: NAPZAR.DLL HaviGyujtokbeMasolas
 *
 * Endpointok:
 * - POST /{branchId}/{yearMonth}  — havi zárás végrehajtás
 * - GET  /{branchId}/{yearMonth}  — havi összesítő lekérdezés
 * - GET  /{branchId}              — összes lezárt hónap listája
 */
@RestController
@RequestMapping("/api/v1/closing/monthly")
@RequiredArgsConstructor
public class MonthlyClosingController {

    private final MonthlyClosingService monthlyClosingService;

    /**
     * Havi zárás végrehajtása.
     */
    @PostMapping("/{branchId}/{yearMonth}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<MonthlyClosingSummary> performMonthlyClosing(
            @PathVariable UUID branchId,
            @PathVariable String yearMonth) {
        MonthlyClosingSummary summary = monthlyClosingService.performMonthlyClosing(branchId, yearMonth);
        return ResponseEntity.status(HttpStatus.CREATED).body(summary);
    }

    /**
     * Havi összesítő lekérdezés.
     */
    @GetMapping("/{branchId}/{yearMonth}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<MonthlyClosingSummary> getMonthlyReport(
            @PathVariable UUID branchId,
            @PathVariable String yearMonth) {
        return ResponseEntity.ok(monthlyClosingService.getMonthlyReport(branchId, yearMonth));
    }

    /**
     * Összes lezárt hónap listája.
     */
    @GetMapping("/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<MonthlyClosingSummary>> getAllClosedMonths(
            @PathVariable UUID branchId) {
        return ResponseEntity.ok(monthlyClosingService.getAllClosedMonths(branchId));
    }
}

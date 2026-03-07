package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStepDto;
import hu.puzzleir.valuta.service.ClosingWizardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Zárási varázsló controller.
 *
 * Napi/POS/dekádos/havi zárás varázsló kezelése.
 */
@RestController
@RequestMapping("/api/v1/closing-wizard")
@RequiredArgsConstructor
public class ClosingWizardController {

    private final ClosingWizardService closingWizardService;

    /**
     * Varázsló indítása
     *
     * POST /api/v1/closing-wizard/start?branchId=&cashDeskId=&closingType=&workerId=
     */
    @PostMapping("/start")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardDto> startWizard(
            @RequestParam UUID branchId,
            @RequestParam(required = false) UUID cashDeskId,
            @RequestParam String closingType,
            @RequestParam Long workerId) {
        ClosingWizardDto result = closingWizardService.startWizard(branchId, cashDeskId, closingType, workerId);
        return ResponseEntity.ok(result);
    }

    /**
     * Varázsló lekérése
     *
     * GET /api/v1/closing-wizard/{wizardId}
     */
    @GetMapping("/{wizardId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardDto> getWizard(@PathVariable UUID wizardId) {
        ClosingWizardDto result = closingWizardService.getWizard(wizardId);
        return ResponseEntity.ok(result);
    }

    /**
     * Adott lépés lekérése
     *
     * GET /api/v1/closing-wizard/{wizardId}/step/{stepNumber}
     */
    @GetMapping("/{wizardId}/step/{stepNumber}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardStepDto> getStep(
            @PathVariable UUID wizardId,
            @PathVariable int stepNumber) {
        ClosingWizardStepDto result = closingWizardService.getStep(wizardId, stepNumber);
        return ResponseEntity.ok(result);
    }

    /**
     * Navigáció adott lépésre
     *
     * POST /api/v1/closing-wizard/{wizardId}/navigate?targetStep=
     */
    @PostMapping("/{wizardId}/navigate")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardDto> navigate(
            @PathVariable UUID wizardId,
            @RequestParam int targetStep) {
        ClosingWizardDto result = closingWizardService.navigate(wizardId, targetStep);
        return ResponseEntity.ok(result);
    }

    /**
     * Varázsló befejezése
     *
     * POST /api/v1/closing-wizard/{wizardId}/complete?workerId=
     */
    @PostMapping("/{wizardId}/complete")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardDto> complete(
            @PathVariable UUID wizardId,
            @RequestParam Long workerId) {
        ClosingWizardDto result = closingWizardService.complete(wizardId, workerId);
        return ResponseEntity.ok(result);
    }

    /**
     * Varázsló megszakítása
     *
     * POST /api/v1/closing-wizard/{wizardId}/cancel
     */
    @PostMapping("/{wizardId}/cancel")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ClosingWizardDto> cancel(@PathVariable UUID wizardId) {
        ClosingWizardDto result = closingWizardService.cancel(wizardId);
        return ResponseEntity.ok(result);
    }

    // ============ STEP-SPECIFIC ENDPOINTS ============

    /**
     * Step 1: Nyitott tranzakciók validálása
     *
     * GET /api/v1/closing-wizard/validate-transactions/{branchId}
     */
    @GetMapping("/validate-transactions/{branchId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<String>> validateOpenTransactions(@PathVariable UUID branchId) {
        List<String> errors = closingWizardService.validateOpenTransactions(branchId);
        return ResponseEntity.ok(errors);
    }

    /**
     * Step 2: Címletolvasó
     *
     * POST /api/v1/closing-wizard/{wizardId}/denominations
     */
    @PostMapping("/{wizardId}/denominations")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> countDenominations(
            @PathVariable UUID wizardId,
            @Valid @RequestBody Map<String, Map<Integer, Integer>> denomCounts) {
        ClosingWizardDto wizard = closingWizardService.getWizard(wizardId);
        Map<String, Object> result = closingWizardService.countDenominations(
                UUID.fromString(wizard.getBranchId()), denomCounts);
        return ResponseEntity.ok(result);
    }

    /**
     * Step 3: Eltérés számítás
     *
     * POST /api/v1/closing-wizard/{wizardId}/differences
     */
    @PostMapping("/{wizardId}/differences")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Map<String, Object>>> calculateDifferences(
            @PathVariable UUID wizardId,
            @Valid @RequestBody Map<String, BigDecimal> physicalCounts) {
        ClosingWizardDto wizard = closingWizardService.getWizard(wizardId);
        List<Map<String, Object>> result = closingWizardService.calculateDifferences(
                UUID.fromString(wizard.getBranchId()), physicalCounts);
        return ResponseEntity.ok(result);
    }

    /**
     * Step 4: Zárási riport generálás
     *
     * GET /api/v1/closing-wizard/{wizardId}/report
     */
    @GetMapping("/{wizardId}/report")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> generateClosingReport(@PathVariable UUID wizardId) {
        Map<String, Object> report = closingWizardService.generateClosingReport(wizardId);
        return ResponseEntity.ok(report);
    }

    /**
     * Step 5: Zárás véglegesítése
     *
     * POST /api/v1/closing-wizard/{wizardId}/finalize?workerId=
     */
    @PostMapping("/{wizardId}/finalize")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> finalizeClosing(
            @PathVariable UUID wizardId,
            @RequestParam Long workerId) {
        boolean success = closingWizardService.finalizeClosing(wizardId, workerId);
        return ResponseEntity.ok(Map.of("success", success, "message",
                success ? "Napzárás véglegesítve!" : "Napzárás sikertelen!"));
    }
}

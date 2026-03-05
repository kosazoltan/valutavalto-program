package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardDto;
import hu.puzzleir.valuta.dto.closingwizard.ClosingWizardStepDto;
import hu.puzzleir.valuta.service.ClosingWizardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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
}

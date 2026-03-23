package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.CommissionCalculation;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.CommissionCalculationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Jutalék számítás controller.
 *
 * Endpointok:
 * - POST /calculate                   — egyetlen pénztáros jutalékszámítás
 * - POST /calculate-all               — iroda összes pénztárosának jutalékszámítása
 * - POST /{id}/approve                — jutalék jóváhagyás
 * - GET  /report?branchId=&month=     — jutalék riport
 */
@RestController
@RequestMapping("/api/v1/commissions")
@RequiredArgsConstructor
public class CommissionCalculationController {

    private final CommissionCalculationService service;

    /**
     * Egyetlen pénztáros jutalék számítása.
     */
    @PostMapping("/calculate")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CommissionCalculation> calculate(
            @RequestParam(required = false) Long workerId,
            @RequestParam String month) {
        UUID companyId = extractCompanyId();
        Long effectiveWorkerId = workerId != null ? workerId : SecurityUtils.getCurrentWorkerId();
        CommissionCalculation result = service.calculateMonthly(effectiveWorkerId, month, companyId);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * Iroda összes pénztárosának jutalék számítása.
     */
    @PostMapping("/calculate-all")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CommissionCalculation>> calculateAll(
            @RequestParam(required = false) UUID branchId,
            @RequestParam String month) {
        UUID companyId = extractCompanyId();
        UUID effectiveBranchId = branchId != null ? branchId : SecurityUtils.getCurrentBranchId();
        List<CommissionCalculation> results = service.calculateAllWorkers(effectiveBranchId, month, companyId);
        return ResponseEntity.status(HttpStatus.CREATED).body(results);
    }

    /**
     * Jutalék jóváhagyása.
     */
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CommissionCalculation> approve(@PathVariable UUID id) {
        return ResponseEntity.ok(service.approveCommission(id));
    }

    /**
     * Jutalék riport.
     */
    @GetMapping("/report")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CommissionCalculation>> report(
            @RequestParam String month) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return ResponseEntity.ok(service.getCommissionReport(branchId, month));
    }

    private UUID extractCompanyId() {
        return SecurityUtils.getCurrentCompanyId();
    }
}

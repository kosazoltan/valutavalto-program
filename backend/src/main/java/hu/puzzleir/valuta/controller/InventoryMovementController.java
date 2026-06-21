package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.inventory.InventoryBalanceDto;
import hu.puzzleir.valuta.dto.inventory.InventoryMovementDto;
import hu.puzzleir.valuta.service.InventoryMovementService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * KĂ©szlet mozgĂˇs naplĂł controller.
 *
 * GET /api/v1/inventory/movements?branchId=&currency=&date=
 * GET /api/v1/inventory/balance?branchId=&currency=&date=
 * POST /api/v1/inventory/adjustment â€” supervisor only (lĂˇsd InventoryController.correction)
 */
@RestController
@RequestMapping("/api/v1/inventory-movements")
@RequiredArgsConstructor
public class InventoryMovementController {

    private final InventoryMovementService inventoryMovementService;

    /**
     * KĂ©szlet mozgĂˇsok listĂˇzĂˇsa
     */
    @GetMapping("/movement-log")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'IRODAVEZETO', 'ERTEKTAR')")
    public ResponseEntity<List<InventoryMovementDto>> getMovements(
            @RequestParam UUID branchId,
            @RequestParam(required = false) String currency,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(inventoryMovementService.getMovements(branchId, currency, date));
    }

    /**
     * Napi kĂ©szlet egyenleg
     */
    @GetMapping("/daily-balance")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'IRODAVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryBalanceDto> getDailyBalance(
            @RequestParam UUID branchId,
            @RequestParam(required = false) String currency,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(inventoryMovementService.getDailyBalance(branchId, currency, date));
    }
}

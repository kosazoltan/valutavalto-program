package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.inventory.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.InventoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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
 * Készlet mozgás controller.
 *
 * Legacy: ERTEKTAR — keszup, keszedit, atadvet, penztarak
 */
@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
public class InventoryController {

    private final InventoryService inventoryService;

    // ============ STOCK QUERIES ============

    @GetMapping("/stock")
    public ResponseEntity<List<CashBalance>> getAllStock() {
        // Összes iroda készlete — lekérdezés az összes CashBalance-ből
        // Megjegyzés: éles környezetben paginated + company szűrős lenne
        return ResponseEntity.ok(List.of()); // placeholder — a service szinten megoldott
    }

    @GetMapping("/stock/{branchId}")
    public ResponseEntity<List<CashBalance>> getStockByBranch(@PathVariable UUID branchId) {
        return ResponseEntity.ok(inventoryService.getCurrentStock(branchId));
    }

    @GetMapping("/matrix")
    public ResponseEntity<StockMatrixDto> getStockMatrix() {
        return ResponseEntity.ok(inventoryService.getStockMatrix());
    }

    // ============ BANK OPERATIONS ============

    @PostMapping("/bank-withdraw")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<InventoryMovementDto> bankWithdraw(
            @Valid @RequestBody BankWithdrawRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.requestBankWithdraw(dto, workerId));
    }

    @PostMapping("/bank-deposit")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<InventoryMovementDto> bankDeposit(
            @Valid @RequestBody BankDepositRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.depositToBank(dto, workerId));
    }

    // ============ BRANCH TRANSFER ============

    @PostMapping("/transfer")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<InventoryMovementDto> transfer(
            @Valid @RequestBody BranchTransferRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.transferBetweenBranches(dto, workerId));
    }

    // ============ CORRECTION ============

    @PostMapping("/correction")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<InventoryMovementDto> correction(
            @Valid @RequestBody CorrectionRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.correctInventory(dto, workerId));
    }

    // ============ STATUS TRANSITIONS ============

    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<InventoryMovementDto> approve(@PathVariable Long id, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(inventoryService.approveMovement(id, workerId));
    }

    @PostMapping("/{id}/receive")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<InventoryMovementDto> receive(
            @PathVariable Long id,
            @Valid @RequestBody ReceiveMovementDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(inventoryService.receiveMovement(id, workerId, dto));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> cancel(@PathVariable Long id) {
        inventoryService.cancelMovement(id);
        return ResponseEntity.noContent().build();
    }

    // ============ MOVEMENT HISTORY ============

    @GetMapping("/movements")
    public ResponseEntity<Page<InventoryMovementDto>> searchMovements(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) MovementStatus status,
            @RequestParam(required = false) MovementType type,
            Pageable pageable) {
        return ResponseEntity.ok(inventoryService.searchMovements(
                branchId, startDate, endDate, status, type, pageable));
    }

    @GetMapping("/movements/{id}")
    public ResponseEntity<InventoryMovementDto> getMovement(@PathVariable Long id) {
        return ResponseEntity.ok(inventoryService.getMovement(id));
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}

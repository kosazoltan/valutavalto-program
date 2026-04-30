package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.dto.inventory.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.BranchService;
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
    private final BranchService branchService;

    // ============ STOCK QUERIES ============

    /**
     * 2026-04-29 v2.3.10 (E-B11 fix): a CashBalance entity helyett CashBalanceDto-t
     * adunk vissza, ami a frontend `currencyCode` + `branchName` field-jeit kitölti.
     * Az entity közvetlen serializációja LAZY-load miatt üresen hagyta ezeket
     * a mezőket → a /inventory oldalon "VALUTA: -" + "PENZTAR: -" jelent meg.
     */
    @GetMapping("/stock")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<CashBalanceDto>> getAllStock() {
        return ResponseEntity.ok(
                inventoryService.getAllStock().stream()
                        .map(InventoryController::toCashBalanceDto)
                        .toList());
    }

    @GetMapping("/stock/{branchId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<CashBalanceDto>> getStockByBranch(@PathVariable UUID branchId) {
        validateBranchAccess(branchId);
        return ResponseEntity.ok(
                inventoryService.getCurrentStock(branchId).stream()
                        .map(InventoryController::toCashBalanceDto)
                        .toList());
    }

    /** Entity → DTO mapping (currency.code + branch.name + minBalance/maxBalance) */
    private static CashBalanceDto toCashBalanceDto(CashBalance cb) {
        return CashBalanceDto.builder()
                .id(cb.getId())
                .branchId(cb.getBranch() != null ? cb.getBranch().getId().toString() : null)
                .branchName(cb.getBranch() != null ? cb.getBranch().getName() : null)
                .currencyId(cb.getCurrency() != null ? cb.getCurrency().getId() : null)
                .currencyCode(cb.getCurrency() != null ? cb.getCurrency().getCode() : null)
                .currencyName(cb.getCurrency() != null ? cb.getCurrency().getName() : null)
                .currentBalance(cb.getCurrentBalance())
                .openingBalance(cb.getOpeningBalance())
                .minBalance(cb.getMinBalance())
                .maxBalance(cb.getMaxBalance())
                .updatedAt(cb.getUpdatedAt())
                .build();
    }

    @GetMapping("/matrix")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<StockMatrixDto> getStockMatrix() {
        return ResponseEntity.ok(inventoryService.getStockMatrix());
    }

    /**
     * v2.4.9: Értéktár (VAULT entity_type) készlete valutára bontva.
     *
     * Az "Értéktári készlet" oldal adatforrása, NEM a pénztáraké.
     * A pénztári készletek a /api/v1/inventory/stock endpointon érhetők el.
     */
    @GetMapping("/vault-stock")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'IRODAVEZETO')")
    public ResponseEntity<List<VaultStockRowDto>> getVaultStock() {
        return ResponseEntity.ok(inventoryService.getVaultStockFlow());
    }

    // ============ BANK OPERATIONS ============

    @PostMapping("/bank-withdraw")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> bankWithdraw(
            @Valid @RequestBody BankWithdrawRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.requestBankWithdraw(dto, workerId));
    }

    @PostMapping("/bank-deposit")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> bankDeposit(
            @Valid @RequestBody BankDepositRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.depositToBank(dto, workerId));
    }

    // ============ BRANCH TRANSFER ============

    @PostMapping("/transfer")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> transfer(
            @Valid @RequestBody BranchTransferRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.transferBetweenBranches(dto, workerId));
    }

    // ============ CORRECTION ============

    @PostMapping("/correction")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> correction(
            @Valid @RequestBody CorrectionRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.correctInventory(dto, workerId));
    }

    // ============ STATUS TRANSITIONS ============

    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> approve(@PathVariable Long id, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(inventoryService.approveMovement(id, workerId));
    }

    @PostMapping("/{id}/receive")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> receive(
            @PathVariable Long id,
            @Valid @RequestBody ReceiveMovementDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(inventoryService.receiveMovement(id, workerId, dto));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<Void> cancel(@PathVariable Long id) {
        inventoryService.cancelMovement(id);
        return ResponseEntity.noContent().build();
    }

    // ============ MOVEMENT HISTORY ============

    @GetMapping("/movements")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
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
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<InventoryMovementDto> getMovement(@PathVariable Long id) {
        return ResponseEntity.ok(inventoryService.getMovement(id));
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new ValidationException("Hitelesítés szükséges!");
    }

    /**
     * IDOR védelem: ellenőrzi, hogy a megadott branchId az aktuális felhasználó cégéhez tartozik-e.
     * A BranchService.findById már tartalmaz company-szintű IDOR védelmet.
     */
    private void validateBranchAccess(UUID branchId) {
        // BranchService.findById throws ResourceNotFoundException if branch doesn't belong to current company
        branchService.findById(branchId);
    }
}

package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.dto.inventory.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AccessScopeService;
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
import java.util.Set;
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
    private final AccessScopeService accessScopeService;

    // ============ STOCK QUERIES ============

    /**
     * 2026-04-29 v2.3.10 (E-B11 fix): a CashBalance entity helyett CashBalanceDto-t
     * adunk vissza, ami a frontend `currencyCode` + `branchName` field-jeit kitölti.
     * Az entity közvetlen serializációja LAZY-load miatt üresen hagyta ezeket
     * a mezőket → a /inventory oldalon "VALUTA: -" + "PENZTAR: -" jelent meg.
     */
    // FK-005/A1: ERTEKTAR (értéktáros) is láthatja a pénztári készleteket — eddig 403-at kapott.
    // FK-005/A3: az értéktáros CSAK a saját region_code-jához tartozó pénztárakat látja
    // (a scope null cég-szintű role-nál → nincs szűkítés).
    @GetMapping("/stock")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<List<CashBalanceDto>> getAllStock() {
        Set<UUID> scope = accessScopeService.vaultRegionBranchScopeOrNull();
        List<CashBalanceDto> dtos = inventoryService.getAllStock().stream()
                .map(InventoryController::toCashBalanceDto)
                .filter(dto -> accessScopeService.isBranchVisible(scope, dto.getBranchId()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @GetMapping("/stock/{branchId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
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
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<StockMatrixDto> getStockMatrix() {
        return ResponseEntity.ok(inventoryService.getStockMatrix());
    }

    /**
     * v2.4.9: Értéktár (VAULT entity_type) készlete valutára bontva.
     *
     * Az "Értéktári készlet" oldal adatforrása, NEM a pénztáraké.
     * A pénztári készletek a /api/v1/inventory/stock endpointon érhetők el.
     */
    // FK-ÉRTÉKTÁR (2026-06-02): az ERTEKTAR (lokál értéktáros) láthatja a SAJÁT értéktára készletét.
    // A menüben elérhető "Értéktári készlet" oldal eddig 403-at adott ERTEKTAR role-lal (audit P0).
    // A getVaultStockFlow() territory-scoped szűrése (getCurrentTerritoryFilterOrNull) gondoskodik
    // arról, hogy az értéktáros csak a saját vault_territory-jának készletét lássa.
    @GetMapping("/vault-stock")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'IRODAVEZETO', 'ERTEKTAR')")
    public ResponseEntity<List<VaultStockRowDto>> getVaultStock() {
        return ResponseEntity.ok(inventoryService.getVaultStockFlow());
    }

    // ============ BANK OPERATIONS ============

    @PostMapping("/bank-withdraw")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryMovementDto> bankWithdraw(
            @Valid @RequestBody BankWithdrawRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.requestBankWithdraw(dto, workerId));
    }

    @PostMapping("/bank-deposit")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryMovementDto> bankDeposit(
            @Valid @RequestBody BankDepositRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.depositToBank(dto, workerId));
    }

    // ============ BRANCH TRANSFER ============

    @PostMapping("/transfer")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryMovementDto> transfer(
            @Valid @RequestBody BranchTransferRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.transferBetweenBranches(dto, workerId));
    }

    @GetMapping("/transfer-targets")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<List<TransferTargetDto>> getTransferTargets() {
        UUID currentBranchId = SecurityUtils.getCurrentBranchId();
        return ResponseEntity.ok(inventoryService.getTransferTargets(currentBranchId).stream()
                .map(branch -> new TransferTargetDto(
                        branch.getId(),
                        branch.getCode(),
                        branch.getName(),
                        Boolean.TRUE.equals(branch.getIsVault())))
                .toList());
    }

    public record TransferTargetDto(UUID branchId, String code, String name, boolean isVault) {}

    // ============ CORRECTION ============

    @PostMapping("/correction")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryMovementDto> correction(
            @Valid @RequestBody CorrectionRequestDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(inventoryService.correctInventory(dto, workerId));
    }

    // ============ STATUS TRANSITIONS ============

    @PostMapping("/{id}/approve")
    // FK-xxx (2026-07-03): ERTEKTAR jóváhagyhat — a 4-szem-elvet a service-szintű self-approval tilalom garantálja (InventoryService.approveMovement).
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryMovementDto> approve(@PathVariable Long id, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(inventoryService.approveMovement(id, workerId));
    }

    @PostMapping("/{id}/receive")
    // FK-xxx (2026-07-03): ERTEKTAR jóváhagyhat — a 4-szem-elvet a service-szintű self-approval tilalom garantálja (InventoryService.approveMovement).
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<InventoryMovementDto> receive(
            @PathVariable Long id,
            @Valid @RequestBody ReceiveMovementDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(inventoryService.receiveMovement(id, workerId, dto));
    }

    @PostMapping("/{id}/cancel")
    // FK-xxx (2026-07-03): ERTEKTAR jóváhagyhat — a 4-szem-elvet a service-szintű self-approval tilalom garantálja (InventoryService.approveMovement).
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
    public ResponseEntity<Void> cancel(@PathVariable Long id) {
        inventoryService.cancelMovement(id);
        return ResponseEntity.noContent().build();
    }

    // ============ MOVEMENT HISTORY ============

    @GetMapping("/movements")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
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
    // FK-xxx (2026-07-03): ERTEKTAR jóváhagyhat — a 4-szem-elvet a service-szintű self-approval tilalom garantálja (InventoryService.approveMovement).
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'ERTEKTAR')")
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

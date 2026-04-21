package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ertektar.*;
import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Ertektar (Vault/Treasury) modul — egyseges REST API.
 * Begyujtes, szeosztas, konszolidalt riportok, alarendelt penztar monitoring.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/ertektar")
@RequiredArgsConstructor
public class ErtektarController {

    private final VaultCollectionService vaultCollectionService;
    private final VaultDistributionService vaultDistributionService;
    private final VaultBankTransactionService vaultBankTransactionService;
    private final VaultTransferService vaultTransferService;
    private final MaterialReceiptService materialReceiptService;
    private final StockCorrectionService stockCorrectionService;
    private final ConsolidatedReportService consolidatedReportService;
    private final BranchMonitoringService branchMonitoringService;

    // === BEGYUJTES (Collections) ===

    /**
     * Begyujtesi kerelmek listazasa.
     * GET /api/v1/ertektar/collections
     */
    @GetMapping("/collections")
    public ResponseEntity<List<CollectionResponseDto>> getCollections() {
        return ResponseEntity.ok(vaultCollectionService.getCollections());
    }

    /**
     * Uj begyujtesi kerelem letrehozasa.
     * POST /api/v1/ertektar/collections
     */
    @PostMapping("/collections")
    public ResponseEntity<CollectionResponseDto> createCollection(
            @Valid @RequestBody CollectionRequestDto request) {
        return ResponseEntity.ok(vaultCollectionService.createCollection(request));
    }

    /**
     * Begyujtes statusz frissitese.
     * PATCH /api/v1/ertektar/collections/{id}/status
     */
    @PatchMapping("/collections/{id}/status")
    public ResponseEntity<CollectionResponseDto> updateCollectionStatus(
            @PathVariable Long id,
            @RequestParam VaultOperationStatus status) {
        return ResponseEntity.ok(vaultCollectionService.updateStatus(id, status));
    }

    // === SZEOSZTAS (Distribution) ===

    /**
     * Szeosztasok listazasa.
     * GET /api/v1/ertektar/distribution
     */
    @GetMapping("/distribution")
    public ResponseEntity<List<DistributionResponseDto>> getDistributions() {
        return ResponseEntity.ok(vaultDistributionService.getDistributions());
    }

    /**
     * Batch szeosztas letrehozasa.
     * POST /api/v1/ertektar/distribution
     */
    @PostMapping("/distribution")
    public ResponseEntity<DistributionResponseDto> createDistribution(
            @Valid @RequestBody DistributionRequestDto request) {
        return ResponseEntity.ok(vaultDistributionService.createDistribution(request));
    }

    /**
     * Szeosztas statusz frissitese.
     * PATCH /api/v1/ertektar/distribution/{id}/status
     */
    @PatchMapping("/distribution/{id}/status")
    public ResponseEntity<DistributionResponseDto> updateDistributionStatus(
            @PathVariable Long id,
            @RequestParam VaultOperationStatus status) {
        return ResponseEntity.ok(vaultDistributionService.updateStatus(id, status));
    }

    // === BANKI TRANZAKCIOK (Bank Transactions — MATPTAR) ===

    /**
     * Banki tranzakciok listazasa.
     * GET /api/v1/ertektar/bank-transactions
     */
    @GetMapping("/bank-transactions")
    public ResponseEntity<List<BankTransactionResponseDto>> getBankTransactions() {
        return ResponseEntity.ok(vaultBankTransactionService.getBankTransactions());
    }

    /**
     * Banki tranzakciok szurese tipus szerint.
     * GET /api/v1/ertektar/bank-transactions?type=BUY
     */
    @GetMapping("/bank-transactions/by-type")
    public ResponseEntity<List<BankTransactionResponseDto>> getBankTransactionsByType(
            @RequestParam String type) {
        return ResponseEntity.ok(vaultBankTransactionService.getBankTransactionsByType(type));
    }

    /**
     * Banki tranzakcio letrehozasa es vegrehajtasa.
     * POST /api/v1/ertektar/bank-transactions
     */
    @PostMapping("/bank-transactions")
    public ResponseEntity<BankTransactionResponseDto> createBankTransaction(
            @Valid @RequestBody BankTransactionRequestDto request) {
        return ResponseEntity.ok(vaultBankTransactionService.createBankTransaction(request));
    }

    /**
     * Banki tranzakcio statusz frissitese.
     * PATCH /api/v1/ertektar/bank-transactions/{id}/status
     */
    @PatchMapping("/bank-transactions/{id}/status")
    public ResponseEntity<BankTransactionResponseDto> updateBankTransactionStatus(
            @PathVariable Long id,
            @RequestParam VaultOperationStatus status) {
        return ResponseEntity.ok(vaultBankTransactionService.updateStatus(id, status));
    }

    /**
     * Deviza beerkezett a bankunktol - deviza oldali megerositese.
     * POST /api/v1/ertektar/bank-transactions/{id}/confirm-received
     */
    @PostMapping("/bank-transactions/{id}/confirm-received")
    public ResponseEntity<BankTransactionResponseDto> confirmBankTransactionReceived(@PathVariable Long id) {
        return ResponseEntity.ok(vaultBankTransactionService.confirmReceived(id));
    }

    /**
     * HUF atutalas megtortent a banknak - HUF oldali megerositese.
     * POST /api/v1/ertektar/bank-transactions/{id}/confirm-paid
     */
    @PostMapping("/bank-transactions/{id}/confirm-paid")
    public ResponseEntity<BankTransactionResponseDto> confirmBankTransactionPaid(@PathVariable Long id) {
        return ResponseEntity.ok(vaultBankTransactionService.confirmPaid(id));
    }

    // === ERTEKKTAR KOEZI ATTETEL (Vault Transfers - ATADVET) ===

    /**
     * Attelek listazasa.
     * GET /api/v1/ertektar/transfers
     */
    @GetMapping("/transfers")
    public ResponseEntity<List<VaultTransferResponseDto>> getTransfers() {
        return ResponseEntity.ok(vaultTransferService.getTransfers());
    }

    /**
     * Fuggo attelek listazasa.
     * GET /api/v1/ertektar/transfers/pending
     */
    @GetMapping("/transfers/pending")
    public ResponseEntity<List<VaultTransferResponseDto>> getPendingTransfers() {
        return ResponseEntity.ok(vaultTransferService.getPendingTransfers());
    }

    /**
     * Uj attetel kérelem letrehozasa.
     * POST /api/v1/ertektar/transfers
     */
    @PostMapping("/transfers")
    public ResponseEntity<VaultTransferResponseDto> createTransfer(
            @Valid @RequestBody VaultTransferRequestDto request) {
        return ResponseEntity.ok(vaultTransferService.createTransfer(request));
    }

    /**
     * Attetel szupervisor jovahagyas.
     * POST /api/v1/ertektar/transfers/{id}/supervisor-approve
     */
    @PostMapping("/transfers/{id}/supervisor-approve")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN')")
    public ResponseEntity<VaultTransferResponseDto> supervisorApproveTransfer(
            @PathVariable Long id) {
        return ResponseEntity.ok(vaultTransferService.supervisorApprove(id));
    }

    /**
     * Attetel vegrehajtasa / atvetele.
     * POST /api/v1/ertektar/transfers/{id}/complete
     */
    @PostMapping("/transfers/{id}/complete")
    public ResponseEntity<VaultTransferResponseDto> completeTransfer(
            @PathVariable Long id) {
        return ResponseEntity.ok(vaultTransferService.completeTransfer(id));
    }

    /**
     * Attetel elutasitasa.
     * POST /api/v1/ertektar/transfers/{id}/reject
     */
    @PostMapping("/transfers/{id}/reject")
    public ResponseEntity<VaultTransferResponseDto> rejectTransfer(
            @PathVariable Long id) {
        return ResponseEntity.ok(vaultTransferService.rejectTransfer(id));
    }

    // === BIZONYLATOK (Material Receipts — MATBIZONYLAT) ===

    /**
     * Bizonylatok listazasa.
     * GET /api/v1/ertektar/receipts
     */
    @GetMapping("/receipts")
    public ResponseEntity<List<MaterialReceiptResponseDto>> getReceipts() {
        return ResponseEntity.ok(materialReceiptService.getReceipts());
    }

    /**
     * Bizonylatok szurese tipus szerint.
     * GET /api/v1/ertektar/receipts/by-type?type=B
     */
    @GetMapping("/receipts/by-type")
    public ResponseEntity<List<MaterialReceiptResponseDto>> getReceiptsByType(
            @RequestParam String type) {
        return ResponseEntity.ok(materialReceiptService.getReceiptsByType(type));
    }

    /**
     * Uj bizonylat letrehozasa (DRAFT allapotban).
     * POST /api/v1/ertektar/receipts
     */
    @PostMapping("/receipts")
    public ResponseEntity<MaterialReceiptResponseDto> createReceipt(
            @Valid @RequestBody MaterialReceiptRequestDto request) {
        return ResponseEntity.ok(materialReceiptService.createReceipt(request));
    }

    /**
     * Bizonylat veglegesitese — keszetmozgas vegrehajtasa.
     * POST /api/v1/ertektar/receipts/{id}/finalize
     */
    @PostMapping("/receipts/{id}/finalize")
    public ResponseEntity<MaterialReceiptResponseDto> finalizeReceipt(
            @PathVariable Long id) {
        return ResponseEntity.ok(materialReceiptService.finalizeReceipt(id));
    }

    // === KESZLETKORREKCIOK (Stock Corrections — KESZEDIT) ===

    /**
     * Korrekciok listazasa.
     * GET /api/v1/ertektar/corrections
     */
    @GetMapping("/corrections")
    public ResponseEntity<List<StockCorrectionResponseDto>> getCorrections() {
        return ResponseEntity.ok(stockCorrectionService.getCorrections());
    }

    /**
     * Fuggo korrekciok listazasa.
     * GET /api/v1/ertektar/corrections/pending
     */
    @GetMapping("/corrections/pending")
    public ResponseEntity<List<StockCorrectionResponseDto>> getPendingCorrections() {
        return ResponseEntity.ok(stockCorrectionService.getPendingCorrections());
    }

    /**
     * Uj korrekcios kerelem letrehozasa.
     * POST /api/v1/ertektar/corrections
     */
    @PostMapping("/corrections")
    public ResponseEntity<StockCorrectionResponseDto> createCorrection(
            @Valid @RequestBody StockCorrectionRequestDto request) {
        return ResponseEntity.ok(stockCorrectionService.createCorrection(request));
    }

    /**
     * Korrekció jovahagyas — keszlet effektiv modositasa.
     * POST /api/v1/ertektar/corrections/{id}/approve
     */
    @PostMapping("/corrections/{id}/approve")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'ADMIN')")
    public ResponseEntity<StockCorrectionResponseDto> approveCorrection(
            @PathVariable Long id) {
        return ResponseEntity.ok(stockCorrectionService.approveCorrection(id));
    }

    /**
     * Korrekció elutasitasa.
     * POST /api/v1/ertektar/corrections/{id}/reject
     */
    @PostMapping("/corrections/{id}/reject")
    public ResponseEntity<StockCorrectionResponseDto> rejectCorrection(
            @PathVariable Long id) {
        return ResponseEntity.ok(stockCorrectionService.rejectCorrection(id));
    }

    // === KONSZOLIDALT RIPORTOK ===

    /**
     * Osszevont riport lekerdezese datumtartomany alapjan.
     * GET /api/v1/ertektar/reports/consolidated?from=2026-03-01&to=2026-03-15
     * Ha a parameterek hianyoznak, az aktualis honap elso napjatol a mai napig ad vissza adatot.
     */
    @GetMapping("/reports/consolidated")
    public ResponseEntity<ConsolidatedReportResponseDto> getConsolidatedReport(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        LocalDate resolvedTo = to != null ? to : LocalDate.now();
        LocalDate resolvedFrom = from != null ? from : resolvedTo.withDayOfMonth(1);
        return ResponseEntity.ok(consolidatedReportService.getConsolidatedReport(resolvedFrom, resolvedTo));
    }

    // === ALARENDELT PENZTARAK MONITORING ===

    /**
     * Alarendelt penztarak statusza (az Ertektar Dashboard-hoz).
     * GET /api/v1/ertektar/branches
     */
    @GetMapping("/branches")
    public ResponseEntity<Map<UUID, BranchStatusResponse>> getBranches() {
        return ResponseEntity.ok(branchMonitoringService.getBranchDashboard());
    }

    /**
     * Backward-compatible alias az Electron SyncEngine klienshez.
     * GET /api/v1/ertektar/branches/status
     */
    @GetMapping("/branches/status")
    public ResponseEntity<Map<UUID, BranchStatusResponse>> getBranchesStatus() {
        return ResponseEntity.ok(branchMonitoringService.getBranchDashboard());
    }
}

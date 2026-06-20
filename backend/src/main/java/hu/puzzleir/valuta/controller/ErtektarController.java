package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ertektar.*;
import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.service.*;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.StringUtils;
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
    // Audit 2026-05-31 (P2 #10): a /bank-transactions AZONNAL készletmozgást könyvel (COMPLETED),
    // dedup nélkül — a penztar-client sync-engine timeout-retry-jánál duplikált VaultBankTransaction
    // + duplikált készletmozgás (sérti a "készlet = SUM(tx)" invariánst). IdempotencyGuard-dal védjük.
    private final IdempotencyGuard idempotencyGuard;

    private static final String ENDPOINT_BANK_TX = "POST /api/v1/ertektar/bank-transactions";

    /**
     * FK-037 (2026-06-20): a kozponti ertektari szerepkorok (FOERTEKTAR/UGYVEZETO) read-only
     * (listazo GET) hozzaferese. Az iras/letrehozas/jovahagyas tovabbra is az osztaly-szintu
     * SUPERVISOR/MANAGER/ADMIN (illetve a szukebb supervisor-approve/approve) szabaly szerint
     * megy — ez a konstans CSAK a lekerdezo vegpontokon engedi a kozponti vezetoi ralatast.
     * (annotacio-erteknek static final String compile-time konstans kell.)
     */
    static final String READ_ROLES =
            "hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')";

    // === BEGYUJTES (Collections) ===

    /**
     * Begyujtesi kerelmek listazasa.
     * GET /api/v1/ertektar/collections
     */
    @GetMapping("/collections")
    @PreAuthorize(READ_ROLES)
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
    @PreAuthorize(READ_ROLES)
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
    @PreAuthorize(READ_ROLES)
    public ResponseEntity<List<BankTransactionResponseDto>> getBankTransactions() {
        return ResponseEntity.ok(vaultBankTransactionService.getBankTransactions());
    }

    /**
     * Banki tranzakciok szurese tipus szerint.
     * GET /api/v1/ertektar/bank-transactions?type=BUY
     */
    @GetMapping("/bank-transactions/by-type")
    @PreAuthorize(READ_ROLES)
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
            @Valid @RequestBody BankTransactionRequestDto request,
            HttpServletRequest httpRequest) {
        // Idempotencia (audit P2 #10): a sync-engine Idempotency-Key-t küld; az IdempotencyFilter a
        // hiányzó header-t már 400-zal elutasítja. Itt a tényleges deduplikációt végezzük (azonos
        // kulcs → cache-elt válasz, nincs dupla készletmozgás), a TransactionController mintájára.
        String idempotencyKey = resolveIdempotencyKey(httpRequest);
        IdempotencyGuard.Acquired<BankTransactionResponseDto> acquired =
                idempotencyGuard.tryAcquire(idempotencyKey, ENDPOINT_BANK_TX, request, BankTransactionResponseDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.ok(acquired.cachedResult());
        }
        try {
            BankTransactionResponseDto result = vaultBankTransactionService.createBankTransaction(request);
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.ok(result);
        } catch (RuntimeException e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    private String resolveIdempotencyKey(HttpServletRequest request) {
        String key = request.getHeader("Idempotency-Key");
        if (StringUtils.hasText(key)) {
            return key;
        }
        return request.getHeader("X-Idempotency-Key");
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
    @PreAuthorize(READ_ROLES)
    public ResponseEntity<List<VaultTransferResponseDto>> getTransfers() {
        return ResponseEntity.ok(vaultTransferService.getTransfers());
    }

    /**
     * Fuggo attelek listazasa.
     * GET /api/v1/ertektar/transfers/pending
     */
    @GetMapping("/transfers/pending")
    @PreAuthorize(READ_ROLES)
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
    @PreAuthorize(READ_ROLES)
    public ResponseEntity<List<MaterialReceiptResponseDto>> getReceipts() {
        return ResponseEntity.ok(materialReceiptService.getReceipts());
    }

    /**
     * Bizonylatok szurese tipus szerint.
     * GET /api/v1/ertektar/receipts/by-type?type=B
     */
    @GetMapping("/receipts/by-type")
    @PreAuthorize(READ_ROLES)
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
    @PreAuthorize(READ_ROLES)
    public ResponseEntity<List<StockCorrectionResponseDto>> getCorrections() {
        return ResponseEntity.ok(stockCorrectionService.getCorrections());
    }

    /**
     * Fuggo korrekciok listazasa.
     * GET /api/v1/ertektar/corrections/pending
     */
    @GetMapping("/corrections/pending")
    @PreAuthorize(READ_ROLES)
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
    @PreAuthorize(READ_ROLES)
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
    @PreAuthorize(READ_ROLES)
    public ResponseEntity<Map<UUID, BranchStatusResponse>> getBranches() {
        return ResponseEntity.ok(branchMonitoringService.getBranchDashboard());
    }

    /**
     * Backward-compatible alias az Electron SyncEngine klienshez.
     * GET /api/v1/ertektar/branches/status
     */
    @GetMapping("/branches/status")
    @PreAuthorize(READ_ROLES)
    public ResponseEntity<Map<UUID, BranchStatusResponse>> getBranchesStatus() {
        return ResponseEntity.ok(branchMonitoringService.getBranchDashboard());
    }
}

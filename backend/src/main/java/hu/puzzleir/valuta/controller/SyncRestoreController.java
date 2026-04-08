package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Szerver → Pénztár visszaállítási endpoint.
 *
 * Ha egy pénztár hardware-e tönkremegy és adatvesztés lép fel,
 * ezzel az endpointtal automatikusan visszaolvashatók a szerveren tárolt adatok.
 *
 * Kétirányú szinkronizáció:
 * - Pénztár → Szerver: SyncController (meglévő)
 * - Szerver → Pénztár: EZ az endpoint (új)
 */
@RestController
@RequestMapping("/api/v1/sync/restore")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@Slf4j
public class SyncRestoreController {

    private final TransactionRepository transactionRepository;

    /**
     * Pénztár tranzakció-történet visszaállítása a szerverről.
     * Az Electron kliens ezt hívja ha adatvesztést észlel vagy friss telepítés történt.
     *
     * GET /api/v1/sync/restore/transactions?since=2026-01-01
     */
    @GetMapping("/transactions")
    public ResponseEntity<List<Map<String, Object>>> getTransactionsForRestore(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate since) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        log.info("Sync restore kérés: branchId={}, since={}", branchId, since);

        List<Transaction> transactions = transactionRepository
                .findByBranchIdAndTransactionDateAfterOrderByTransactionDateAsc(
                        branchId, since);

        List<Map<String, Object>> result = transactions.stream()
                .map(this::toRestoreDto)
                .collect(Collectors.toList());

        log.info("Sync restore: {} tranzakció visszaküldve (since={})", result.size(), since);
        return ResponseEntity.ok(result);
    }

    /**
     * Pénztár sync állapot — mennyi adat van a szerveren ehhez a branch-hez.
     *
     * GET /api/v1/sync/restore/status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getRestoreStatus() {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        long totalTransactions = transactionRepository.countByBranchId(branchId);
        LocalDate earliest = transactionRepository.findEarliestDateByBranchId(branchId);
        LocalDate latest = transactionRepository.findLatestDateByBranchId(branchId);

        Map<String, Object> status = new LinkedHashMap<>();
        status.put("branchId", branchId.toString());
        status.put("totalTransactions", totalTransactions);
        status.put("earliestDate", earliest != null ? earliest.toString() : null);
        status.put("latestDate", latest != null ? latest.toString() : null);
        status.put("restoreAvailable", totalTransactions > 0);

        return ResponseEntity.ok(status);
    }

    private Map<String, Object> toRestoreDto(Transaction tx) {
        Map<String, Object> dto = new LinkedHashMap<>();
        dto.put("id", tx.getId());
        dto.put("type", tx.getTransactionType().name());
        dto.put("currencyCode", tx.getCurrency() != null ? tx.getCurrency().getCode() : null);
        dto.put("currencyAmount", tx.getCurrencyAmount());
        dto.put("hufAmount", tx.getHufAmount());
        dto.put("rate", tx.getExchangeRate());
        dto.put("handlingFee", tx.getHandlingFee());
        dto.put("transactionDate", tx.getTransactionDate() != null ? tx.getTransactionDate().toString() : null);
        dto.put("receiptNumber", tx.getReceiptNumber());
        dto.put("status", tx.getStatus() != null ? tx.getStatus().name() : null);
        return dto;
    }
}

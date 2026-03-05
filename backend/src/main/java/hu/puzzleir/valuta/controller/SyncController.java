package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.sync.SyncLogDto;
import hu.puzzleir.valuta.dto.sync.SyncStatusDto;
import hu.puzzleir.valuta.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Sync controller — fiók szinkronizáció.
 */
@RestController
@RequestMapping("/api/v1/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService service;

    @PostMapping("/rates/{branchId}")
    public ResponseEntity<SyncLogDto> syncRates(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.syncRatesDown(branchId));
    }

    @PostMapping("/transactions/{branchId}")
    public ResponseEntity<SyncLogDto> syncTransactions(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.syncTransactionsUp(branchId));
    }

    @PostMapping("/inventory/{branchId}")
    public ResponseEntity<SyncLogDto> syncInventory(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.syncInventoryUp(branchId));
    }

    @PostMapping("/full/{branchId}")
    public ResponseEntity<SyncLogDto> syncFull(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.syncAll(branchId));
    }

    @GetMapping("/status/{branchId}")
    public ResponseEntity<SyncStatusDto> getStatus(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.getSyncStatus(branchId));
    }

    @GetMapping("/history/{branchId}")
    public ResponseEntity<Page<SyncLogDto>> getHistory(@PathVariable UUID branchId, Pageable pageable) {
        return ResponseEntity.ok(service.getSyncHistory(branchId, pageable));
    }
}

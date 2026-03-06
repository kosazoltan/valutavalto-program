package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ftpsync.FtpSyncLogDto;
import hu.puzzleir.valuta.dto.ftpsync.FtpSyncResultDto;
import hu.puzzleir.valuta.service.FtpSyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FTP szinkronizáció controller.
 * Legacy FTP kompatibilitás — bridge az új REST API felé.
 */
@RestController
@RequestMapping("/api/v1/ftp-sync")
@RequiredArgsConstructor
public class FtpSyncController {

    private final FtpSyncService ftpSyncService;

    @PostMapping("/rates/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FtpSyncResultDto> syncRates(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ftpSyncService.syncRateFile(branchId));
    }

    @PostMapping("/daily-report/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FtpSyncResultDto> uploadDailyReport(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(ftpSyncService.uploadDailyReport(branchId, date));
    }

    @PostMapping("/transactions/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<FtpSyncResultDto> uploadTransactions(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ftpSyncService.uploadTransactionBatch(branchId));
    }

    @GetMapping("/history/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<FtpSyncLogDto>> getSyncHistory(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ftpSyncService.getSyncHistory(branchId));
    }
}

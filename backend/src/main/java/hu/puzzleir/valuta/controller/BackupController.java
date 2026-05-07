package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.backup.BackupRecordResponse;
import hu.puzzleir.valuta.dto.backup.CreateBackupRequest;
import hu.puzzleir.valuta.entity.BackupStatus;
import hu.puzzleir.valuta.entity.BackupType;
import hu.puzzleir.valuta.service.BackupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

/**
 * Backup controller — mentés, visszaállítás, előzmények.
 * Csak ADMIN szerepkör érheti el.
 */
@RestController
@RequestMapping("/api/v1/backup")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class BackupController {

    private final BackupService backupService;

    /**
     * Új backup mentés létrehozása.
     * POST /api/v1/backup/create
     */
    @PostMapping("/create")
    public ResponseEntity<BackupRecordResponse> createBackup(
            @Valid @RequestBody CreateBackupRequest request,
            Principal principal) {
        BackupRecordResponse response = backupService.createBackup(request.getType(), resolveCreatedBy(principal));
        return ResponseEntity.status(httpStatusForBackup(response.getStatus())).body(response);
    }

    /**
     * Backup visszaállítás.
     * POST /api/v1/backup/{id}/restore
     */
    @PostMapping("/{id}/restore")
    public ResponseEntity<Void> restoreBackup(@PathVariable UUID id) {
        backupService.restoreBackup(id);
        return ResponseEntity.ok().build();
    }

    /**
     * Backup előzmények.
     * GET /api/v1/backup/history
     */
    @GetMapping("/history")
    public ResponseEntity<Page<BackupRecordResponse>> getHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(backupService.getBackupHistory(page, size));
    }

    /**
     * Backup fájl letöltés.
     * GET /api/v1/backup/{id}/download
     */
    @GetMapping("/{id}/download")
    public ResponseEntity<byte[]> downloadBackup(@PathVariable UUID id) {
        byte[] data = backupService.downloadBackup(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=backup_" + id + ".sql")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(data);
    }

    private String resolveCreatedBy(Principal principal) {
        if (principal == null || principal.getName() == null || principal.getName().isBlank()) {
            return "unknown";
        }
        return principal.getName();
    }

    private HttpStatus httpStatusForBackup(BackupStatus status) {
        return switch (status) {
            case COMPLETED -> HttpStatus.OK;
            case RUNNING -> HttpStatus.ACCEPTED;
            case FAILED -> HttpStatus.SERVICE_UNAVAILABLE;
        };
    }
}

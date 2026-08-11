package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.CameraAccessLog;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.service.CameraAccessService;
import hu.puzzleir.valuta.service.CameraCleanupService;
import hu.puzzleir.valuta.service.CameraUploadService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Kamera-adminisztráció (konfiguráció, tárhely, takarítás, hozzáférési napló).
 *
 * <p><b>Réteg-megjegyzés.</b> A korábbi négy közvetlen repository-injektálás és a
 * {@code CameraController}-rel <b>bitre azonos</b> privát {@code enforceBranchAccess}
 * megszűnt: mindkettő a közös {@link CameraAccessService}-be került, tranzakción belülre.
 * Egy tenant-guard két másolatban két helyen driftelhetne szét.
 */
@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@RestController
@RequestMapping("/api/v1/camera/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class CameraAdminController {

    private final CameraCleanupService cleanupService;
    private final CameraUploadService uploadService;
    private final CameraAccessService cameraAccessService;

    /**
     * List all camera configurations.
     * GET /api/v1/camera/admin/configs
     */
    @GetMapping("/configs")
    public ResponseEntity<List<CameraConfig>> getConfigs(
            @RequestParam(required = false) UUID branchId) {
        if (branchId != null) {
            return ResponseEntity.ok(cameraAccessService.getConfigsForBranch(branchId));
        }
        return ResponseEntity.ok(cameraAccessService.getAccessibleConfigs());
    }

    /**
     * Create or update camera configuration.
     * POST /api/v1/camera/admin/configs
     */
    @PostMapping("/configs")
    public ResponseEntity<CameraConfig> saveConfig(@Valid @RequestBody CameraConfig config) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(cameraAccessService.saveConfig(config));
    }

    /**
     * Delete camera configuration.
     * DELETE /api/v1/camera/admin/configs/{id}
     */
    @DeleteMapping("/configs/{id}")
    public ResponseEntity<Void> deleteConfig(@PathVariable UUID id) {
        cameraAccessService.deleteConfig(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Get storage statistics.
     * GET /api/v1/camera/admin/storage-stats
     */
    @GetMapping("/storage-stats")
    public ResponseEntity<CameraCleanupService.StorageStats> getStorageStats() {
        return ResponseEntity.ok(cleanupService.getStorageStats());
    }

    /**
     * Manual cleanup of expired recordings.
     * POST /api/v1/camera/admin/cleanup
     */
    @PostMapping("/cleanup")
    public ResponseEntity<Map<String, Object>> manualCleanup(
            @Valid @RequestBody(required = false) Map<String, String> body) {
        LocalDate beforeDate = LocalDate.now().minusDays(50);
        if (body != null && body.containsKey("beforeDate")) {
            beforeDate = LocalDate.parse(body.get("beforeDate"));
        }
        int deleted = cleanupService.manualCleanup(beforeDate);
        return ResponseEntity.ok(Map.of("deletedCount", deleted, "beforeDate", beforeDate.toString()));
    }

    /**
     * Get pending upload count.
     * GET /api/v1/camera/admin/upload-status
     */
    @GetMapping("/upload-status")
    public ResponseEntity<Map<String, Integer>> getUploadStatus() {
        return ResponseEntity.ok(Map.of("pendingUploads", uploadService.getPendingUploadCount()));
    }

    /**
     * Get access logs for a recording.
     * GET /api/v1/camera/admin/access-logs/{recordingId}
     */
    @GetMapping("/access-logs/{recordingId}")
    public ResponseEntity<List<CameraAccessLog>> getAccessLogs(@PathVariable UUID recordingId) {
        return ResponseEntity.ok(cameraAccessService.getAccessLogs(recordingId));
    }
}

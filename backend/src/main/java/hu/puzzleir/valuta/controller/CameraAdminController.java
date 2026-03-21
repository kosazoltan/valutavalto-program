package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraAccessLog;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
import java.util.stream.Collectors;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@RestController
@RequestMapping("/api/v1/camera/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class CameraAdminController {

    private final CameraConfigRepository configRepository;
    private final CameraAccessLogRepository accessLogRepository;
    private final CameraCleanupService cleanupService;
    private final CameraUploadService uploadService;
    private final BranchRepository branchRepository;
    private final CameraRecordingRepository recordingRepository;

    /**
     * List all camera configurations.
     * GET /api/v1/camera/admin/configs
     */
    @GetMapping("/configs")
    public ResponseEntity<List<CameraConfig>> getConfigs(
            @RequestParam(required = false) UUID branchId) {
        if (branchId != null) {
            enforceBranchAccess(branchId);
            return ResponseEntity.ok(configRepository.findByBranchId(branchId));
        }
        return ResponseEntity.ok(getAccessibleConfigs());
    }

    /**
     * Create or update camera configuration.
     * POST /api/v1/camera/admin/configs
     */
    @PostMapping("/configs")
    public ResponseEntity<CameraConfig> saveConfig(@Valid @RequestBody CameraConfig config) {
        enforceBranchAccess(config.getBranchId());
        return ResponseEntity.status(HttpStatus.CREATED).body(configRepository.save(config));
    }

    /**
     * Delete camera configuration.
     * DELETE /api/v1/camera/admin/configs/{id}
     */
    @DeleteMapping("/configs/{id}")
    public ResponseEntity<Void> deleteConfig(@PathVariable UUID id) {
        CameraConfig config = configRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Kamera konfiguráció nem található: " + id));
        enforceBranchAccess(config.getBranchId());
        configRepository.deleteById(id);
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
        CameraRecording recording = recordingRepository.findById(recordingId)
                .orElseThrow(() -> new ResourceNotFoundException("Kamera felvétel nem található: " + recordingId));
        enforceBranchAccess(recording.getBranchId());
        return ResponseEntity.ok(accessLogRepository.findByRecordingIdOrderByCreatedAtDesc(recordingId));
    }

    private List<CameraConfig> getAccessibleConfigs() {
        return branchRepository.findByCompanyId(SecurityUtils.getCurrentCompanyId()).stream()
                .map(Branch::getId)
                .flatMap(branchId -> configRepository.findByBranchId(branchId).stream())
                .collect(Collectors.toList());
    }

    private void enforceBranchAccess(UUID branchId) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (branch.getCompany() == null || !currentCompanyId.equals(branch.getCompany().getId())) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
    }
}

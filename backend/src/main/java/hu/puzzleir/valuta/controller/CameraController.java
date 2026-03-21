package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.camera.CameraStatusDto;
import hu.puzzleir.valuta.dto.camera.RecordingMetadataDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraAccessLog;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.CameraRecordingService;
import hu.puzzleir.valuta.service.CameraTransactionLinker;
import hu.puzzleir.valuta.util.TransactionIdentityCodec;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@RestController
@RequestMapping("/api/v1/camera")
@RequiredArgsConstructor
public class CameraController {

    private final CameraRecordingService recordingService;
    private final CameraTransactionLinker transactionLinker;
    private final CameraRecordingRepository recordingRepository;
    private final CameraTransactionLinkRepository linkRepository;
    private final CameraAccessLogRepository accessLogRepository;
    private final CameraConfigRepository cameraConfigRepository;
    private final BranchRepository branchRepository;

    /**
     * Get live JPEG frame from a camera.
     * GET /api/v1/camera/stream/{cameraId}
     */
    @GetMapping(value = "/stream/{cameraId}", produces = MediaType.IMAGE_JPEG_VALUE)
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> getLiveFrame(@PathVariable String cameraId) {
        enforceCameraAccess(cameraId);
        byte[] frame = recordingService.getLiveFrame(cameraId);
        if (frame == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.CACHE_CONTROL, "no-cache, no-store, must-revalidate")
                .body(frame);
    }

    /**
     * Get status of all cameras.
     * GET /api/v1/camera/status
     */
    @GetMapping("/status")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<CameraStatusDto>> getCameraStatus() {
        Set<String> allowedCameraIds = getAllowedCameraIds();
        Set<String> activeCameras = recordingService.getActiveCameraIds();
        List<CameraStatusDto> statuses = new ArrayList<>();

        for (String cameraId : activeCameras) {
            if (!allowedCameraIds.contains(cameraId)) {
                continue;
            }
            statuses.add(CameraStatusDto.builder()
                    .cameraId(cameraId)
                    .recording(recordingService.isRecording(cameraId))
                    .connected(true)
                    .currentSegmentFile(null)
                    .build());
        }

        return ResponseEntity.ok(statuses);
    }

    /**
     * Search recordings by branch and date range.
     * GET /api/v1/camera/recordings?branchId=...&start=...&end=...
     */
    @GetMapping("/recordings")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<RecordingMetadataDto>> getRecordings(
            @RequestParam UUID branchId,
            @RequestParam LocalDateTime start,
            @RequestParam LocalDateTime end) {

        enforceBranchAccess(branchId);

        List<CameraRecording> recordings = recordingRepository
                .findByBranchIdAndStartTimeBetween(branchId, start, end);

        List<RecordingMetadataDto> dtos = recordings.stream()
                .map(this::toMetadataDto)
                .collect(Collectors.toList());

        return ResponseEntity.ok(dtos);
    }

    /**
     * Get a single recording metadata.
     * GET /api/v1/camera/recordings/{id}
     */
    @GetMapping("/recordings/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<RecordingMetadataDto> getRecording(@PathVariable UUID id) {
        CameraRecording recording = recordingRepository.findById(id)
                .orElse(null);
        if (recording == null) {
            return ResponseEntity.notFound().build();
        }
        enforceBranchAccess(recording.getBranchId());

        // Audit log
        logAccess(recording, "VIEW");

        return ResponseEntity.ok(toMetadataDto(recording));
    }

    /**
     * Search recordings by receipt number.
     * GET /api/v1/camera/recordings/by-receipt/{receiptNumber}
     */
    @GetMapping("/recordings/by-receipt/{receiptNumber}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<CameraTransactionLink>> findByReceipt(
            @PathVariable String receiptNumber) {
        List<CameraTransactionLink> links = transactionLinker.findByReceiptNumber(receiptNumber).stream()
                .filter(this::canAccessLink)
                .collect(Collectors.toList());
        return ResponseEntity.ok(links);
    }

    /**
     * Search recordings by transaction ID.
     * GET /api/v1/camera/recordings/by-transaction/{transactionId}
     * Elfogad UUID-t vagy legacy LONG transaction ID-t is.
     */
    @GetMapping("/recordings/by-transaction/{transactionId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<CameraTransactionLink>> findByTransaction(
            @PathVariable String transactionId) {
        List<CameraTransactionLink> links = transactionLinker.findByTransactionId(
                        TransactionIdentityCodec.parseUuidOrLegacyLong(transactionId)).stream()
                .filter(this::canAccessLink)
                .collect(Collectors.toList());
        return ResponseEntity.ok(links);
    }

    private RecordingMetadataDto toMetadataDto(CameraRecording r) {
        int linkedTx = linkRepository.findByRecordingId(r.getId()).size();
        return RecordingMetadataDto.builder()
                .id(r.getId())
                .branchId(r.getBranchId())
                .cameraId(r.getCameraId())
                .startTime(r.getStartTime())
                .endTime(r.getEndTime())
                .fileSizeBytes(r.getFileSizeBytes())
                .uploadedToServer(Boolean.TRUE.equals(r.getUploadedToServer()))
                .expiresAt(r.getExpiresAt())
                .status(r.getStatus().name())
                .linkedTransactions(linkedTx)
                .build();
    }

    private Set<String> getAllowedCameraIds() {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        return branchRepository.findByCompanyId(currentCompanyId).stream()
                .map(Branch::getId)
                .flatMap(branchId -> cameraConfigRepository.findByBranchIdAndEnabled(branchId, true).stream())
                .map(CameraConfig::getCameraId)
                .collect(Collectors.toSet());
    }

    private void enforceCameraAccess(String cameraId) {
        if (!getAllowedCameraIds().contains(cameraId)) {
            throw new ResourceNotFoundException("Kamera nem található: " + cameraId);
        }
    }

    private void enforceBranchAccess(UUID branchId) {
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (branch.getCompany() == null || !currentCompanyId.equals(branch.getCompany().getId())) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
    }

    private boolean canAccessLink(CameraTransactionLink link) {
        try {
            UUID branchId = link.getRecording() != null ? link.getRecording().getBranchId() : null;
            if (branchId == null) {
                return false;
            }
            enforceBranchAccess(branchId);
            return true;
        } catch (RuntimeException ex) {
            return false;
        }
    }

    private void logAccess(CameraRecording recording, String action) {
        try {
            CameraAccessLog log = CameraAccessLog.builder()
                    .recording(recording)
                    .workerId(SecurityUtils.getCurrentWorkerId())
                    .action(action)
                    .build();
            accessLogRepository.save(log);
        } catch (Exception ignored) {
            // Don't fail the main operation if audit logging fails
        }
    }
}

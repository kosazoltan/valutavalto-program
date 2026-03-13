package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.camera.CameraStatusDto;
import hu.puzzleir.valuta.dto.camera.RecordingMetadataDto;
import hu.puzzleir.valuta.entity.CameraAccessLog;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.CameraRecordingService;
import hu.puzzleir.valuta.service.CameraTransactionLinker;
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

@RestController
@RequestMapping("/api/v1/camera")
@RequiredArgsConstructor
public class CameraController {

    private final CameraRecordingService recordingService;
    private final CameraTransactionLinker transactionLinker;
    private final CameraRecordingRepository recordingRepository;
    private final CameraTransactionLinkRepository linkRepository;
    private final CameraAccessLogRepository accessLogRepository;

    /**
     * Get live JPEG frame from a camera.
     * GET /api/v1/camera/stream/{cameraId}
     */
    @GetMapping(value = "/stream/{cameraId}", produces = MediaType.IMAGE_JPEG_VALUE)
    public ResponseEntity<byte[]> getLiveFrame(@PathVariable String cameraId) {
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
    public ResponseEntity<List<CameraStatusDto>> getCameraStatus() {
        Set<String> activeCameras = recordingService.getActiveCameraIds();
        List<CameraStatusDto> statuses = new ArrayList<>();

        for (String cameraId : activeCameras) {
            CameraRecording active = recordingService.getActiveRecording(cameraId);
            statuses.add(CameraStatusDto.builder()
                    .cameraId(cameraId)
                    .recording(recordingService.isRecording(cameraId))
                    .connected(true)
                    .currentSegmentFile(active != null ? active.getLocalFilePath() : null)
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
        List<CameraTransactionLink> links = transactionLinker.findByReceiptNumber(receiptNumber);
        return ResponseEntity.ok(links);
    }

    /**
     * Search recordings by transaction ID.
     * GET /api/v1/camera/recordings/by-transaction/{transactionId}
     */
    @GetMapping("/recordings/by-transaction/{transactionId}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<CameraTransactionLink>> findByTransaction(
            @PathVariable UUID transactionId) {
        List<CameraTransactionLink> links = transactionLinker.findByTransactionId(transactionId);
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

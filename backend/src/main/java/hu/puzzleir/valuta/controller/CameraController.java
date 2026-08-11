package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.camera.CameraStatusDto;
import hu.puzzleir.valuta.dto.camera.RecordingMetadataDto;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.service.CameraAccessService;
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

/**
 * Kamera-végpontok (live stream, felvétel-keresés).
 *
 * <p><b>Réteg-megjegyzés.</b> Ez a controller korábban öt repository-t injektált
 * közvetlenül, és a tenant-guardot saját privát metódusban tartotta. Az adatelérés és a
 * jogosultság-ellenőrzés mostantól a {@link CameraAccessService} use-case rétegében,
 * tranzakción belül fut — az OSIV ki van kapcsolva, és a guard lazy asszociációt olvas.
 * A controller feladata csak a HTTP-leképezés és a DTO-építés.
 */
@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@RestController
@RequestMapping("/api/v1/camera")
@RequiredArgsConstructor
public class CameraController {

    private final CameraRecordingService recordingService;
    private final CameraTransactionLinker transactionLinker;
    private final CameraAccessService cameraAccessService;

    /**
     * Get live JPEG frame from a camera.
     * GET /api/v1/camera/stream/{cameraId}
     */
    @GetMapping(value = "/stream/{cameraId}", produces = MediaType.IMAGE_JPEG_VALUE)
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> getLiveFrame(@PathVariable String cameraId) {
        cameraAccessService.assertCameraAccessible(cameraId);
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
        Set<String> allowedCameraIds = cameraAccessService.getAllowedCameraIds();
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
                    .frozen(recordingService.isFrozen(cameraId))
                    .lastFreshFrameAt(recordingService.getLastFreshFrameAt(cameraId))
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

        List<RecordingMetadataDto> dtos = cameraAccessService
                .findRecordings(branchId, start, end).stream()
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
        // A tenant-guard es a VIEW audit-bejegyzes a service tranzakciojan belul tortenik.
        CameraRecording recording = cameraAccessService.findRecordingForViewing(id);
        if (recording == null) {
            return ResponseEntity.notFound().build();
        }
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
        return ResponseEntity.ok(cameraAccessService.filterAccessibleLinks(
                transactionLinker.findByReceiptNumber(receiptNumber)));
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
        return ResponseEntity.ok(cameraAccessService.filterAccessibleLinks(
                transactionLinker.findByTransactionId(Long.parseLong(transactionId))));
    }

    private RecordingMetadataDto toMetadataDto(CameraRecording r) {
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
                .linkedTransactions(cameraAccessService.countLinkedTransactions(r.getId()))
                .build();
    }
}

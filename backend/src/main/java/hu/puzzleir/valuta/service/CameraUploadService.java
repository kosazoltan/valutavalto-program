package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.CameraProperties;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@Service
@RequiredArgsConstructor
@Slf4j
public class CameraUploadService {

    private final CameraRecordingRepository recordingRepository;
    private final CameraProperties cameraProperties;

    /**
     * Periodically upload completed segments to the central server.
     * Runs every 5 minutes.
     */
    @Scheduled(fixedDelayString = "${camera.upload-interval-seconds:300}000")
    @Transactional
    public void uploadPendingRecordings() {
        List<CameraRecording> pending = recordingRepository
                .findByUploadedToServerFalseAndStatusIn(
                        List.of(CameraRecording.RecordingStatus.COMPLETED));

        if (pending.isEmpty()) return;

        if (!cameraProperties.isMockUploadEnabled()) {
            log.warn("Kamera szerver-feltöltés nincs implementálva (mockUploadEnabled=false), függő szegmensek: {} db", pending.size());
            return;
        }

        log.info("Feltoltendo szegmensek: {} db", pending.size());

        for (CameraRecording recording : pending) {
            try {
                uploadToServer(recording);
                recording.setUploadedToServer(true);
                recording.setServerFilePath(generateServerPath(recording));
                recordingRepository.save(recording);
                log.info("Szegmens feltoltve: {} ({})", recording.getCameraId(), recording.getId());
            } catch (Exception e) {
                recording.setUploadAttempts(recording.getUploadAttempts() + 1);
                recordingRepository.save(recording);
                log.warn("Feltoltes sikertelen (probalkezas: {}): {} - {}",
                        recording.getUploadAttempts(), recording.getId(), e.getMessage());
            }
        }
    }

    /**
     * Upload a single recording to the server.
     * Mock upload mode only. Real upload implementation is pending.
     */
    private void uploadToServer(CameraRecording recording) {
        log.warn("Mock upload aktiv: {}", recording.getLocalFilePath());
    }

    /**
     * Generate the server-side path for a recording.
     */
    private String generateServerPath(CameraRecording recording) {
        return String.format("/camera-storage/%s/%s/%s",
                recording.getBranchId(),
                recording.getStartTime().toLocalDate(),
                recording.getId());
    }

    /**
     * Get count of pending uploads.
     */
    public int getPendingUploadCount() {
        return recordingRepository
                .findByUploadedToServerFalseAndStatusIn(
                        List.of(CameraRecording.RecordingStatus.COMPLETED))
                .size();
    }
}

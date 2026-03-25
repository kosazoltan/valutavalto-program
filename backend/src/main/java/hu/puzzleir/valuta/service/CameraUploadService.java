package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.CameraProperties;
import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@Service
@RequiredArgsConstructor
@Slf4j
public class CameraUploadService {

    private final CameraRecordingRepository recordingRepository;
    private final CameraProperties cameraProperties;
    private final IntegrationTransportProperties integrationTransportProperties;
    private final FileTransportService fileTransportService;

    /**
     * Periodically upload completed segments to the central server.
     * Runs every 5 minutes.
     */
    @Scheduled(fixedDelayString = "${camera.upload-interval-seconds:300}000")
    @Transactional(rollbackFor = Exception.class)
    public void uploadPendingRecordings() {
        List<CameraRecording> pending = recordingRepository
                .findByUploadedToServerFalseAndStatusIn(
                        List.of(CameraRecording.RecordingStatus.COMPLETED));

        if (pending.isEmpty()) return;

        log.info("Feltöltendő szegmensek: {} db", pending.size());

        for (CameraRecording recording : pending) {
            try {
                String serverPath = uploadToServer(recording);
                recording.setUploadedToServer(true);
                recording.setServerFilePath(serverPath);
                recording.setStatus(CameraRecording.RecordingStatus.UPLOADED);
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
     * Upload a single recording to managed storage.
     */
    private String uploadToServer(CameraRecording recording) throws Exception {
        if (recording.getLocalFilePath() == null || recording.getLocalFilePath().isBlank()) {
            throw new IllegalStateException("Hiányzó localFilePath a kamera szegmenshez: " + recording.getId());
        }

        Path source = Paths.get(recording.getLocalFilePath()).toAbsolutePath().normalize();
        Path expectedRoot = Paths.get(cameraProperties.getLocalStoragePath()).toAbsolutePath().normalize();
        if (!Files.exists(source)) {
            throw new IllegalStateException("A kamera szegmens fájl nem található: " + source);
        }
        Path realRoot = expectedRoot.toRealPath();
        Path realSource = source.toRealPath();
        if (!realSource.startsWith(realRoot)) {
            throw new IllegalStateException("A kamera szegmens forrásfájl kilép a megengedett gyökérből: " + realSource);
        }
        if (Files.isSymbolicLink(source)) {
            throw new IllegalStateException("A kamera szegmens forrásfájl nem lehet symlink: " + source);
        }

        String baseDir = fileTransportService.sanitizePathSegment(
                integrationTransportProperties.getCamera().getUploadDir(), "camera.uploadDir");
        String relativeDir = Paths.get(baseDir,
                fileTransportService.sanitizePathSegment(recording.getBranchId().toString(), "branchId"),
                fileTransportService.sanitizePathSegment(recording.getStartTime().toLocalDate().toString(), "recordingDate")).toString();
        String targetFileName = fileTransportService.sanitizeFileName(recording.getId() + "_" + source.getFileName());
        Path uploaded = fileTransportService.copyToManagedStorage(source, relativeDir, targetFileName);
        log.info("Kamera szegmens feltöltve managed storage-be: {} -> {}", source, uploaded);
        return uploaded.toString();
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

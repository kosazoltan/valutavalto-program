package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;

import com.github.sarxos.webcam.Webcam;
import hu.puzzleir.valuta.config.CameraProperties;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PreDestroy;
import java.awt.Dimension;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
@ConditionalOnProperty(name = "camera.enabled", havingValue = "true", matchIfMissing = false)
@RequiredArgsConstructor
@Slf4j
public class CameraRecordingService {

    private final CameraProperties cameraProperties;
    private final CameraConfigRepository cameraConfigRepository;
    private final CameraRecordingRepository recordingRepository;
    private final CameraStorageService storageService;
    private final CameraEncryptionService encryptionService;
    private final CameraHashChainService hashChainService;

    private final Map<String, Webcam> activeWebcams = new ConcurrentHashMap<>();
    private final Map<String, CameraRecording> activeRecordings = new ConcurrentHashMap<>();
    private final AtomicBoolean running = new AtomicBoolean(false);
    private ExecutorService executorService;

    /**
     * Start recording on application startup if enabled.
     */
    @EventListener(ApplicationReadyEvent.class)
    public void onApplicationReady() {
        if (!cameraProperties.isEnabled()) {
            log.info("Kamera rendszer kikapcsolva (camera.enabled=false)");
            return;
        }
        startAllCameras();
    }

    /**
     * Start all configured cameras for the current branch.
     */
    public void startAllCameras() {
        if (running.getAndSet(true)) {
            log.warn("Kamera rogzites mar fut");
            return;
        }

        List<Webcam> webcams = Webcam.getWebcams();
        if (webcams.isEmpty()) {
            log.warn("Nem talalhato USB webkamera");
            running.set(false);
            return;
        }

        executorService = Executors.newFixedThreadPool(webcams.size());
        log.info("Talalt webkamerak: {}", webcams.size());

        for (int i = 0; i < webcams.size(); i++) {
            Webcam webcam = webcams.get(i);
            String cameraId = "cam" + (i + 1);

            try {
                Dimension resolution = new Dimension(
                        cameraProperties.getResolution().getWidth(),
                        cameraProperties.getResolution().getHeight());
                webcam.setViewSize(resolution);
                webcam.open();
                activeWebcams.put(cameraId, webcam);

                executorService.submit(() -> captureLoop(webcam, cameraId));
                log.info("Kamera inditva: {} ({})", cameraId, webcam.getName());
            } catch (Exception e) {
                log.error("Kamera inditas sikertelen: {}", cameraId, e);
            }
        }
    }

    /**
     * Stop all cameras on application shutdown.
     */
    @PreDestroy
    public void stopAllCameras() {
        running.set(false);
        log.info("Kamera rogzites leallitasa...");

        // Finalize active recordings
        for (Map.Entry<String, CameraRecording> entry : activeRecordings.entrySet()) {
            finalizeRecording(entry.getValue());
        }
        activeRecordings.clear();

        // Close webcams
        for (Map.Entry<String, Webcam> entry : activeWebcams.entrySet()) {
            try {
                entry.getValue().close();
                log.info("Kamera leallitva: {}", entry.getKey());
            } catch (Exception e) {
                log.warn("Kamera leallitas hiba: {}", entry.getKey(), e);
            }
        }
        activeWebcams.clear();

        if (executorService != null) {
            executorService.shutdownNow();
        }
    }

    /**
     * Main capture loop for a camera â€” runs in a separate thread.
     */
    private void captureLoop(Webcam webcam, String cameraId) {
        Thread.currentThread().setName("camera-" + cameraId);
        long frameIntervalMs = 1000 / cameraProperties.getFps();
        UUID branchId = getBranchIdForCamera(cameraId);

        log.info("Capture loop inditva: {} @ {} FPS", cameraId, cameraProperties.getFps());

        while (running.get() && webcam.isOpen()) {
            try {
                // Check if we need a new segment
                CameraRecording recording = activeRecordings.get(cameraId);
                if (recording == null || shouldRotateSegment(recording)) {
                    if (recording != null) {
                        finalizeRecording(recording);
                    }
                    recording = startNewSegment(branchId, cameraId);
                    activeRecordings.put(cameraId, recording);
                }

                // Capture frame
                BufferedImage image = webcam.getImage();
                if (image != null) {
                    byte[] jpegData = storageService.encodeJpeg(image);
                    Path segmentFile = Path.of(recording.getLocalFilePath());
                    storageService.appendFrame(segmentFile, jpegData);
                }

                Thread.sleep(frameIntervalMs);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                log.error("Frame capture hiba: {}", cameraId, e);
                try { Thread.sleep(1000); } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }

        log.info("Capture loop leallt: {}", cameraId);
    }

    /**
     * Start a new recording segment.
     */
    @Transactional(rollbackFor = Exception.class)
    public CameraRecording startNewSegment(UUID branchId, String cameraId) {
        LocalDateTime now = LocalDateTime.now();
        try {
            Path dir = storageService.ensureDirectoryExists(branchId, now.toLocalDate());
            String fileName = storageService.generateSegmentFileName(cameraId, now);
            Path segmentFile = dir.resolve(fileName);

            CameraRecording recording = CameraRecording.builder()
                    .branchId(branchId)
                    .cameraId(cameraId)
                    .startTime(now)
                    .localFilePath(segmentFile.toString())
                    .expiresAt(now.toLocalDate().plusDays(cameraProperties.getRetentionDays()))
                    .status(CameraRecording.RecordingStatus.RECORDING)
                    .build();

            recording = recordingRepository.save(recording);
            log.info("Uj szegmens inditva: {} -> {}", cameraId, fileName);
            return recording;
        } catch (IOException e) {
            log.error("Szegmens inditas sikertelen: {}", cameraId, e);
            throw new BusinessException("Szegmens letrehozas sikertelen", "CAMERA_SEGMENT_FAILED");
        }
    }

    /**
     * Finalize a recording segment.
     */
    @Transactional(rollbackFor = Exception.class)
    public void finalizeRecording(CameraRecording recording) {
        recording.setEndTime(LocalDateTime.now());
        if (recording.getLocalFilePath() == null || recording.getLocalFilePath().isBlank()) {
            recording.setStatus(CameraRecording.RecordingStatus.ERROR);
            recordingRepository.save(recording);
            log.error("Szegmens lezárás sikertelen, hiányzó fájlútvonal: id={}", recording.getId());
            return;
        }

        Path plainPath = Path.of(recording.getLocalFilePath());
        Path finalizedPath = plainPath;

        try {
            if (!Files.exists(plainPath)) {
                throw new IllegalStateException("Kamera szegmens fájl nem található: " + plainPath);
            }

            if (encryptionService.isEncryptionEnabled()
                    && !plainPath.getFileName().toString().toLowerCase(Locale.ROOT).endsWith(".enc")) {
                Path encryptedPath = plainPath.resolveSibling(plainPath.getFileName() + ".enc");
                encryptionService.encryptFile(plainPath, encryptedPath);
                Files.deleteIfExists(plainPath);
                finalizedPath = encryptedPath;
            }

            recording.setLocalFilePath(finalizedPath.toString());
            recording.setFileSizeBytes(storageService.getFileSize(finalizedPath));
            recording.setStatus(CameraRecording.RecordingStatus.COMPLETED);
            CameraRecording saved = recordingRepository.save(recording);

            hashChainService.addToChain(saved, finalizedPath);
            log.info("Szegmens lezarva: {} ({} bytes), hash-lánchoz hozzáadva",
                    saved.getCameraId(), saved.getFileSizeBytes());
        } catch (Exception e) {
            recording.setStatus(CameraRecording.RecordingStatus.ERROR);
            recordingRepository.save(recording);
            log.error("Szegmens lezárás/kriptó/hash sikertelen: id={}", recording.getId(), e);
        }
    }

    /**
     * Check if the current segment should be rotated.
     */
    private boolean shouldRotateSegment(CameraRecording recording) {
        if (recording.getStartTime() == null) return true;
        long minutes = java.time.Duration.between(recording.getStartTime(), LocalDateTime.now()).toMinutes();
        return minutes >= cameraProperties.getSegmentDurationMinutes();
    }

    /**
     * Get branch ID for a camera â€” from config or fallback.
     */
    private UUID getBranchIdForCamera(String cameraId) {
        UUID currentBranchId = resolveCurrentBranchId();
        if (currentBranchId != null) {
            return cameraConfigRepository.findByBranchIdAndCameraId(currentBranchId, cameraId)
                    .map(CameraConfig::getBranchId)
                    .orElse(currentBranchId);
        }

        log.warn("Nincs branch kontextus a kamerahoz: {}, alapertelmezett branch hasznalata", cameraId);
        return UUID.fromString("00000000-0000-0000-0000-000000000001");
    }

    private UUID resolveCurrentBranchId() {
        try {
            return SecurityUtils.getCurrentBranchId();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Get the current live frame from a camera as JPEG bytes.
     */
    public byte[] getLiveFrame(String cameraId) {
        Webcam webcam = activeWebcams.get(cameraId);
        if (webcam == null || !webcam.isOpen()) {
            return null;
        }
        try {
            BufferedImage image = webcam.getImage();
            if (image == null) return null;
            return storageService.encodeJpeg(image);
        } catch (IOException e) {
            log.error("Live frame lekeres sikertelen: {}", cameraId, e);
            return null;
        }
    }

    /**
     * Check if a camera is currently recording.
     */
    public boolean isRecording(String cameraId) {
        return activeWebcams.containsKey(cameraId) && activeWebcams.get(cameraId).isOpen();
    }

    /**
     * Get all active camera IDs.
     */
    public Set<String> getActiveCameraIds() {
        return Collections.unmodifiableSet(activeWebcams.keySet());
    }

    /**
     * Get the active recording for a camera.
     */
    public CameraRecording getActiveRecording(String cameraId) {
        return activeRecordings.get(cameraId);
    }
}

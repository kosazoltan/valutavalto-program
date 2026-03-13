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

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CameraCleanupService {

    private final CameraRecordingRepository recordingRepository;
    private final CameraStorageService storageService;
    private final CameraProperties cameraProperties;

    /**
     * Scheduled cleanup: delete expired recordings (> retention days old).
     * Runs every night at 2:00 AM.
     */
    @Scheduled(cron = "0 0 2 * * *")
    @Transactional
    public void cleanupExpiredRecordings() {
        LocalDate cutoff = LocalDate.now().minusDays(cameraProperties.getRetentionDays());
        log.info("Lejart kamerafelvetelk torlese inditasa (cutoff: {})", cutoff);

        List<CameraRecording> expired = recordingRepository
                .findByExpiresAtBeforeAndStatusNot(cutoff, CameraRecording.RecordingStatus.RECORDING);

        int deletedCount = 0;
        long freedBytes = 0;

        for (CameraRecording recording : expired) {
            // Delete local file
            if (recording.getLocalFilePath() != null) {
                storageService.deleteLocalFile(recording.getLocalFilePath());
                if (recording.getFileSizeBytes() != null) {
                    freedBytes += recording.getFileSizeBytes();
                }
            }

            // Mark as expired
            recording.setStatus(CameraRecording.RecordingStatus.EXPIRED);
            recordingRepository.save(recording);
            deletedCount++;
        }

        log.info("Lejart felvetelek torolve: {} db, felszabaditott hely: {} MB",
                deletedCount, freedBytes / (1024 * 1024));
    }

    /**
     * Manual cleanup trigger (for admin).
     */
    @Transactional
    public int manualCleanup(LocalDate beforeDate) {
        List<CameraRecording> recordings = recordingRepository
                .findByExpiresAtBeforeAndStatusNot(beforeDate, CameraRecording.RecordingStatus.RECORDING);

        int count = 0;
        for (CameraRecording recording : recordings) {
            if (recording.getLocalFilePath() != null) {
                storageService.deleteLocalFile(recording.getLocalFilePath());
            }
            recording.setStatus(CameraRecording.RecordingStatus.EXPIRED);
            recordingRepository.save(recording);
            count++;
        }
        return count;
    }

    /**
     * Get storage statistics.
     */
    public StorageStats getStorageStats() {
        long totalDiskUsage = storageService.getTotalDiskUsage();
        long availableSpace = storageService.getAvailableDiskSpace();
        long totalRecordings = recordingRepository.count();

        return new StorageStats(totalDiskUsage, availableSpace, totalRecordings);
    }

    public record StorageStats(long totalUsageBytes, long availableSpaceBytes, long totalRecordings) {
        public double usagePercent() {
            long total = totalUsageBytes + availableSpaceBytes;
            if (total == 0) return 0;
            return (double) totalUsageBytes / total * 100;
        }
    }
}

package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraSegmentHash;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraSegmentHashRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CameraHashChainServiceTest {

    @Mock
    private CameraSegmentHashRepository hashRepository;
    @Mock
    private CameraRecordingRepository recordingRepository;
    @Mock
    private CameraEncryptionService encryptionService;
    @Mock
    private AuditLogService auditLogService;

    @InjectMocks
    private CameraHashChainService service;

    @Test
    void verifyChain_returnsTrue_whenMetadataMatchesPersistedRecordingStartTime() {
        UUID branchId = UUID.randomUUID();
        UUID recordingId = UUID.randomUUID();
        String cameraId = "cam-01";
        LocalDateTime startTime = LocalDateTime.of(2026, 3, 21, 10, 15, 0);

        String prev = "0000000000000000000000000000000000000000000000000000000000000000";
        String fileHash = "f".repeat(64);
        long size = 1234L;
        String metadata = recordingId + "|" + branchId + "|" + cameraId + "|" + startTime + "|" + size;
        String chainHash = TestHashUtil.sha256(prev + "|" + fileHash + "|" + metadata);

        CameraSegmentHash entry = CameraSegmentHash.builder()
                .recordingId(recordingId)
                .branchId(branchId)
                .cameraId(cameraId)
                .sequenceNumber(1)
                .fileHash(fileHash)
                .previousHash(prev)
                .chainHash(chainHash)
                .fileSizeBytes(size)
                .build();

        CameraRecording recording = CameraRecording.builder()
                .id(recordingId)
                .branchId(branchId)
                .cameraId(cameraId)
                .startTime(startTime)
                .build();

        when(hashRepository.findByBranchIdAndCameraIdOrderBySequenceNumberAsc(branchId, cameraId))
                .thenReturn(List.of(entry));
        when(recordingRepository.findById(recordingId)).thenReturn(Optional.of(recording));

        assertTrue(service.verifyChain(branchId, cameraId));
    }

    @Test
    void verifyChain_returnsFalse_whenRecordingStartTimeDiffersFromHashMetadata() {
        UUID branchId = UUID.randomUUID();
        UUID recordingId = UUID.randomUUID();
        String cameraId = "cam-01";
        LocalDateTime originalStartTime = LocalDateTime.of(2026, 3, 21, 10, 15, 0);
        LocalDateTime changedStartTime = originalStartTime.plusMinutes(5);

        String prev = "0000000000000000000000000000000000000000000000000000000000000000";
        String fileHash = "a".repeat(64);
        long size = 987L;
        String metadata = recordingId + "|" + branchId + "|" + cameraId + "|" + originalStartTime + "|" + size;
        String chainHash = TestHashUtil.sha256(prev + "|" + fileHash + "|" + metadata);

        CameraSegmentHash entry = CameraSegmentHash.builder()
                .recordingId(recordingId)
                .branchId(branchId)
                .cameraId(cameraId)
                .sequenceNumber(1)
                .fileHash(fileHash)
                .previousHash(prev)
                .chainHash(chainHash)
                .fileSizeBytes(size)
                .build();

        CameraRecording recording = CameraRecording.builder()
                .id(recordingId)
                .branchId(branchId)
                .cameraId(cameraId)
                .startTime(changedStartTime)
                .build();

        when(hashRepository.findByBranchIdAndCameraIdOrderBySequenceNumberAsc(branchId, cameraId))
                .thenReturn(List.of(entry));
        when(recordingRepository.findById(recordingId)).thenReturn(Optional.of(recording));

        assertFalse(service.verifyChain(branchId, cameraId));
    }

    private static final class TestHashUtil {
        private static String sha256(String input) {
            try {
                var digest = java.security.MessageDigest.getInstance("SHA-256");
                byte[] hash = digest.digest(input.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                StringBuilder hex = new StringBuilder();
                for (byte b : hash) {
                    hex.append(String.format("%02x", b));
                }
                return hex.toString();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
    }
}

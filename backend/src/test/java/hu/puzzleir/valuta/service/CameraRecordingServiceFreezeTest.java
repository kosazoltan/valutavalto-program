package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.CameraProperties;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class CameraRecordingServiceFreezeTest {

    @Mock private CameraConfigRepository cameraConfigRepository;
    @Mock private CameraRecordingRepository recordingRepository;
    @Mock private CameraStorageService storageService;
    @Mock private CameraEncryptionService encryptionService;
    @Mock private CameraHashChainService hashChainService;

    private CameraRecordingService service;

    private static final LocalDateTime T0 = LocalDateTime.of(2026, 7, 10, 10, 0, 0);
    private static final byte[] FRAME_A = {1, 2, 3};
    private static final byte[] FRAME_B = {4, 5, 6};
    private static final String CAM = "cam1";

    @BeforeEach
    void setUp() {
        CameraProperties props = new CameraProperties();
        props.setFreezeDetectSeconds(120);
        service = new CameraRecordingService(props, cameraConfigRepository,
                recordingRepository, storageService, encryptionService, hashChainService);
    }

    @Test
    void frissFramek_nemFrozen() {
        service.evaluateFrameFreshness(CAM, FRAME_A, T0);
        service.evaluateFrameFreshness(CAM, FRAME_B, T0.plusSeconds(1));
        assertFalse(service.isFrozen(CAM));
        assertEquals(T0.plusSeconds(1), service.getLastFreshFrameAt(CAM));
    }

    @Test
    void azonosFrame_kuszobAlatt_nemFrozen() {
        service.evaluateFrameFreshness(CAM, FRAME_A, T0);
        service.evaluateFrameFreshness(CAM, FRAME_A, T0.plusSeconds(119));
        assertFalse(service.isFrozen(CAM));
    }

    @Test
    void azonosFrame_kuszobFelett_frozen() {
        service.evaluateFrameFreshness(CAM, FRAME_A, T0);
        service.evaluateFrameFreshness(CAM, FRAME_A, T0.plusSeconds(120));
        assertTrue(service.isFrozen(CAM));
        assertEquals(T0, service.getLastFreshFrameAt(CAM));
    }

    @Test
    void nullFramek_kezdettol_kuszobFelett_frozen() {
        service.evaluateFrameFreshness(CAM, null, T0);
        service.evaluateFrameFreshness(CAM, null, T0.plusSeconds(120));
        assertTrue(service.isFrozen(CAM));
    }

    @Test
    void frissFrame_utan_recovery() {
        service.evaluateFrameFreshness(CAM, FRAME_A, T0);
        service.evaluateFrameFreshness(CAM, FRAME_A, T0.plusSeconds(120));
        assertTrue(service.isFrozen(CAM));
        service.evaluateFrameFreshness(CAM, FRAME_B, T0.plusSeconds(121));
        assertFalse(service.isFrozen(CAM));
        assertEquals(T0.plusSeconds(121), service.getLastFreshFrameAt(CAM));
    }

    @Test
    void ismeretlenKamera_nemFrozen_esNullTimestamp() {
        assertFalse(service.isFrozen("nincs-ilyen"));
        assertNull(service.getLastFreshFrameAt("nincs-ilyen"));
    }

    @Test
    void nullCameraId_nemDob() {
        assertDoesNotThrow(() -> service.evaluateFrameFreshness(null, FRAME_A, T0));
        assertFalse(service.isFrozen(null));
        assertNull(service.getLastFreshFrameAt(null));
    }
}

package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.CameraAccessService;
import hu.puzzleir.valuta.service.CameraRecordingService;
import hu.puzzleir.valuta.service.CameraTransactionLinker;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CameraControllerSecurityTest {

    @Mock private CameraRecordingService recordingService;
    @Mock private CameraTransactionLinker transactionLinker;
    @Mock private CameraRecordingRepository recordingRepository;
    @Mock private CameraTransactionLinkRepository linkRepository;
    @Mock private CameraAccessLogRepository accessLogRepository;
    @Mock private CameraConfigRepository cameraConfigRepository;
    @Mock private BranchRepository branchRepository;

    private CameraController controller;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OWN_BRANCH_ID = UUID.randomUUID();
    private static final UUID FOREIGN_BRANCH_ID = UUID.randomUUID();

    /**
     * Réteg-refaktor (2026-08-11): az adatelérés és a tenant-guard a
     * {@link hu.puzzleir.valuta.service.CameraAccessService} use-case rétegébe került.
     *
     * <p><b>Az assertek VÁLTOZATLANOK.</b> A teszt a VALÓDI service-t példányosítja
     * ugyanazokkal a mockolt repository-kkal, amiket korábban a controller kapott —
     * ezért ezek a tesztek most is pontosan azt a végponti viselkedést bizonyítják,
     * mint a refaktor előtt (multi-tenant izoláció, szűrés, 404-szemantika).
     */
    @BeforeEach
    void setUp() {
        CameraAccessService cameraAccessService = new CameraAccessService(
                branchRepository,
                cameraConfigRepository,
                recordingRepository,
                linkRepository,
                accessLogRepository
        );
        controller = new CameraController(
                recordingService,
                transactionLinker,
                cameraAccessService
        );
    }

    @Test
    void getRecordings_rejectsForeignBranch() {
        mockBranch(FOREIGN_BRANCH_ID, UUID.randomUUID());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThrows(ResourceNotFoundException.class,
                    () -> controller.getRecordings(FOREIGN_BRANCH_ID, LocalDateTime.now().minusHours(1), LocalDateTime.now()));
        }
    }

    @Test
    void getRecording_rejectsForeignRecording() {
        CameraRecording recording = CameraRecording.builder()
                .id(UUID.randomUUID())
                .branchId(FOREIGN_BRANCH_ID)
                .cameraId("cam-foreign")
                .startTime(LocalDateTime.now().minusMinutes(5))
                .status(CameraRecording.RecordingStatus.COMPLETED)
                .build();
        when(recordingRepository.findById(recording.getId())).thenReturn(Optional.of(recording));
        mockBranch(FOREIGN_BRANCH_ID, UUID.randomUUID());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThrows(ResourceNotFoundException.class,
                    () -> controller.getRecording(recording.getId()));
        }
    }

    @Test
    void findByTransaction_filtersOutForeignLinks() {
        CameraTransactionLink ownLink = CameraTransactionLink.builder()
                .id(UUID.randomUUID())
                .recording(CameraRecording.builder().id(UUID.randomUUID()).branchId(OWN_BRANCH_ID).cameraId("cam-own").build())
                .transactionId(123L)
                .build();
        CameraTransactionLink foreignLink = CameraTransactionLink.builder()
                .id(UUID.randomUUID())
                .recording(CameraRecording.builder().id(UUID.randomUUID()).branchId(FOREIGN_BRANCH_ID).cameraId("cam-foreign").build())
                .transactionId(123L)
                .build();

        when(transactionLinker.findByTransactionId(any())).thenReturn(List.of(ownLink, foreignLink));
        mockBranch(OWN_BRANCH_ID, COMPANY_ID);
        mockBranch(FOREIGN_BRANCH_ID, UUID.randomUUID());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            List<CameraTransactionLink> result = controller.findByTransaction("123").getBody();
            assertNotNull(result);
            assertEquals(1, result.size());
            assertEquals(OWN_BRANCH_ID, result.get(0).getRecording().getBranchId());
        }
    }

    @Test
    void getCameraStatus_returnsOnlyAllowedCamerasAndHidesPath() {
        when(recordingService.getActiveCameraIds()).thenReturn(Set.of("cam-own", "cam-foreign"));
        when(recordingService.isRecording("cam-own")).thenReturn(true);
        when(cameraConfigRepository.findByBranchIdAndEnabled(OWN_BRANCH_ID, true)).thenReturn(List.of(
                CameraConfig.builder().branchId(OWN_BRANCH_ID).cameraId("cam-own").enabled(true).build()
        ));
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(branch(OWN_BRANCH_ID, COMPANY_ID)));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            var response = controller.getCameraStatus();
            assertNotNull(response.getBody());
            assertEquals(1, response.getBody().size());
            assertEquals("cam-own", response.getBody().get(0).getCameraId());
            assertNull(response.getBody().get(0).getCurrentSegmentFile());
        }
    }

    @Test
    void getCameraStatus_exposesFrozenState() {
        LocalDateTime lastFresh = LocalDateTime.of(2026, 7, 10, 9, 58, 0);
        when(recordingService.getActiveCameraIds()).thenReturn(Set.of("cam-own"));
        when(recordingService.isFrozen("cam-own")).thenReturn(true);
        when(recordingService.getLastFreshFrameAt("cam-own")).thenReturn(lastFresh);
        when(cameraConfigRepository.findByBranchIdAndEnabled(OWN_BRANCH_ID, true)).thenReturn(List.of(
                CameraConfig.builder().branchId(OWN_BRANCH_ID).cameraId("cam-own").enabled(true).build()
        ));
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(branch(OWN_BRANCH_ID, COMPANY_ID)));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            var response = controller.getCameraStatus();
            assertNotNull(response.getBody());
            assertTrue(response.getBody().get(0).isFrozen());
            assertEquals(lastFresh, response.getBody().get(0).getLastFreshFrameAt());
        }
    }

    @Test
    void getLiveFrame_rejectsForeignCamera() {
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(branch(OWN_BRANCH_ID, COMPANY_ID)));
        when(cameraConfigRepository.findByBranchIdAndEnabled(OWN_BRANCH_ID, true)).thenReturn(List.of(
                CameraConfig.builder().branchId(OWN_BRANCH_ID).cameraId("cam-own").enabled(true).build()
        ));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThrows(ResourceNotFoundException.class, () -> controller.getLiveFrame("cam-foreign"));
        }
    }

    private void mockBranch(UUID branchId, UUID companyId) {
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch(branchId, companyId)));
    }

    private Branch branch(UUID branchId, UUID companyId) {
        return Branch.builder()
                .id(branchId)
                .code("BR")
                .name("Branch")
                .company(Company.builder().id(companyId).code("COMP").name("Company").build())
                .bankCode("BANK")
                .address("Addr")
                .city("City")
                .zipCode("0000")
                .build();
    }
}

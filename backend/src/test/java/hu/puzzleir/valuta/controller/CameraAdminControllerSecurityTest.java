package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraAccessLog;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.CameraAccessService;
import hu.puzzleir.valuta.service.CameraCleanupService;
import hu.puzzleir.valuta.service.CameraUploadService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CameraAdminControllerSecurityTest {

    @Mock private CameraConfigRepository configRepository;
    @Mock private CameraAccessLogRepository accessLogRepository;
    @Mock private CameraCleanupService cleanupService;
    @Mock private CameraUploadService uploadService;
    @Mock private BranchRepository branchRepository;
    @Mock private CameraRecordingRepository recordingRepository;
    @Mock private hu.puzzleir.valuta.repository.CameraTransactionLinkRepository linkRepository;

    private CameraAdminController controller;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID OWN_BRANCH_ID = UUID.randomUUID();
    private static final UUID FOREIGN_BRANCH_ID = UUID.randomUUID();

    /**
     * Réteg-refaktor (2026-08-11): az adatelérés és a tenant-guard a
     * {@link CameraAccessService} use-case rétegébe került.
     *
     * <p><b>Az assertek VÁLTOZATLANOK.</b> A teszt a VALÓDI service-t példányosítja
     * ugyanazokkal a mockolt repository-kkal, amiket korábban a controller kapott —
     * ezért továbbra is a végponti viselkedést bizonyítják (cég-szűrés, cross-tenant
     * elutasítás, törlés-tiltás).
     */
    @BeforeEach
    void setUp() {
        CameraAccessService cameraAccessService = new CameraAccessService(
                branchRepository,
                configRepository,
                recordingRepository,
                linkRepository,
                accessLogRepository
        );
        controller = new CameraAdminController(
                cleanupService,
                uploadService,
                cameraAccessService
        );
    }

    @Test
    void getConfigs_withoutBranch_filtersToCurrentCompany() {
        CameraConfig own = CameraConfig.builder().id(UUID.randomUUID()).branchId(OWN_BRANCH_ID).cameraId("own").build();
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(branch(OWN_BRANCH_ID, COMPANY_ID)));
        when(configRepository.findByBranchId(OWN_BRANCH_ID)).thenReturn(List.of(own));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            List<CameraConfig> result = controller.getConfigs(null).getBody();
            assertNotNull(result);
            assertEquals(1, result.size());
            assertEquals(OWN_BRANCH_ID, result.get(0).getBranchId());
            verify(configRepository, never()).findAll();
        }
    }

    @Test
    void getConfigs_withForeignBranch_rejected() {
        when(branchRepository.findById(FOREIGN_BRANCH_ID)).thenReturn(Optional.of(branch(FOREIGN_BRANCH_ID, UUID.randomUUID())));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThrows(ResourceNotFoundException.class, () -> controller.getConfigs(FOREIGN_BRANCH_ID));
        }
    }

    @Test
    void deleteConfig_withForeignBranch_rejected() {
        UUID configId = UUID.randomUUID();
        when(configRepository.findById(configId)).thenReturn(Optional.of(
                CameraConfig.builder().id(configId).branchId(FOREIGN_BRANCH_ID).cameraId("foreign").build()
        ));
        when(branchRepository.findById(FOREIGN_BRANCH_ID)).thenReturn(Optional.of(branch(FOREIGN_BRANCH_ID, UUID.randomUUID())));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThrows(ResourceNotFoundException.class, () -> controller.deleteConfig(configId));
            verify(configRepository, never()).deleteById(any());
        }
    }

    @Test
    void getAccessLogs_withForeignRecording_rejected() {
        UUID recordingId = UUID.randomUUID();
        when(recordingRepository.findById(recordingId)).thenReturn(Optional.of(
                CameraRecording.builder().id(recordingId).branchId(FOREIGN_BRANCH_ID).cameraId("foreign").build()
        ));
        when(branchRepository.findById(FOREIGN_BRANCH_ID)).thenReturn(Optional.of(branch(FOREIGN_BRANCH_ID, UUID.randomUUID())));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThrows(ResourceNotFoundException.class, () -> controller.getAccessLogs(recordingId));
            verify(accessLogRepository, never()).findByRecordingIdOrderByCreatedAtDesc(any());
        }
    }

    @Test
    void saveConfig_withOwnBranch_allowed() {
        CameraConfig config = CameraConfig.builder().id(UUID.randomUUID()).branchId(OWN_BRANCH_ID).cameraId("own").build();
        when(branchRepository.findById(OWN_BRANCH_ID)).thenReturn(Optional.of(branch(OWN_BRANCH_ID, COMPANY_ID)));
        when(configRepository.save(config)).thenReturn(config);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            CameraConfig saved = controller.saveConfig(config).getBody();
            assertNotNull(saved);
            assertEquals(OWN_BRANCH_ID, saved.getBranchId());
        }
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

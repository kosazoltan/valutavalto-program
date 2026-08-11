package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CameraConfig;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraAccessLogRepository;
import hu.puzzleir.valuta.repository.CameraConfigRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.junit.jupiter.api.Nested;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Karakterisztikus (behaviour-preserving) teszt a kamera-hozzáférés use-case rétegéhez.
 *
 * <p>A tesztek a réteg-refaktor <b>ELŐTTI</b>, a két controllerbe ágyazott viselkedést
 * rögzítik — így bizonyítják, hogy a {@link CameraAccessService}-be mozgatás nem
 * változtatott viselkedést:
 *
 * <ul>
 *   <li>cross-tenant fiók → {@code ResourceNotFoundException} „nem található" üzenettel
 *       (nem „nincs jogosultság" — az nem árulhatja el idegen erőforrás létezését),</li>
 *   <li>hiányzó {@code company} asszociáció → szintén elutasítás (null-guard),</li>
 *   <li>nem létező felvétel → {@code null} (a controller 404-et ad), nem kivétel,</li>
 *   <li>idegen tenant kapcsolata csendben kiesik a szűrésből,</li>
 *   <li>az audit-írás hibája NEM bukatja el a fő műveletet.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CameraAccessServiceTest {

    private static final UUID COMPANY_A = UUID.fromString("00000000-0000-0000-0000-00000000000a");
    private static final UUID COMPANY_B = UUID.fromString("00000000-0000-0000-0000-00000000000b");
    private static final UUID BRANCH_ID = UUID.fromString("00000000-0000-0000-0000-0000000000b1");
    private static final UUID RECORDING_ID = UUID.fromString("00000000-0000-0000-0000-0000000000c1");

    @Mock private BranchRepository branchRepository;
    @Mock private CameraConfigRepository cameraConfigRepository;
    @Mock private CameraRecordingRepository recordingRepository;
    @Mock private CameraTransactionLinkRepository linkRepository;
    @Mock private CameraAccessLogRepository accessLogRepository;

    @InjectMocks private CameraAccessService service;

    private MockedStatic<SecurityUtils> securityUtils;

    @BeforeEach
    void setUp() {
        securityUtils = Mockito.mockStatic(SecurityUtils.class);
        securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
        securityUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
    }

    @AfterEach
    void tearDown() {
        securityUtils.close();
    }

    private static Branch branchOf(UUID companyId) {
        Company company = new Company();
        company.setId(companyId);
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCompany(company);
        return branch;
    }

    private static CameraRecording recordingOf(UUID branchId) {
        CameraRecording r = new CameraRecording();
        r.setId(RECORDING_ID);
        r.setBranchId(branchId);
        return r;
    }

    @Nested
    @DisplayName("assertBranchInCurrentCompany — tenant-guard")
    class TenantGuard {

        @Test
        @DisplayName("sajat ceg fiokja atmegy")
        void ownCompanyPasses() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_A)));
            service.assertBranchInCurrentCompany(BRANCH_ID);
        }

        @Test
        @DisplayName("MULTI-TENANT: idegen ceg fiokja 'nem talalhato'-t dob, nem jogosultsagi hibat")
        void foreignCompanyRejected() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_B)));
            ResourceNotFoundException ex = assertThrows(ResourceNotFoundException.class,
                    () -> service.assertBranchInCurrentCompany(BRANCH_ID));
            assertTrue(ex.getMessage().contains("Iroda nem található"),
                    "a hibauzenet nem arulhatja el idegen tenant eroforrasanak letezeset");
        }

        @Test
        @DisplayName("hianyzo company asszociacio eseten is elutasit (null-guard)")
        void nullCompanyRejected() {
            Branch orphan = new Branch();
            orphan.setId(BRANCH_ID);
            orphan.setCompany(null);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(orphan));
            assertThrows(ResourceNotFoundException.class,
                    () -> service.assertBranchInCurrentCompany(BRANCH_ID));
        }

        @Test
        @DisplayName("nem letezo fiok eseten elutasit")
        void missingBranchRejected() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.empty());
            assertThrows(ResourceNotFoundException.class,
                    () -> service.assertBranchInCurrentCompany(BRANCH_ID));
        }
    }

    @Nested
    @DisplayName("getAllowedCameraIds / assertCameraAccessible")
    class CameraScope {

        @Test
        @DisplayName("csak a sajat ceg engedelyezett kamerait adja vissza")
        void onlyOwnCompanyCameras() {
            CameraConfig cfg = new CameraConfig();
            cfg.setCameraId("cam-01");
            when(branchRepository.findByCompanyId(COMPANY_A)).thenReturn(List.of(branchOf(COMPANY_A)));
            when(cameraConfigRepository.findByBranchIdAndEnabled(BRANCH_ID, true)).thenReturn(List.of(cfg));

            assertEquals(java.util.Set.of("cam-01"), service.getAllowedCameraIds());
            service.assertCameraAccessible("cam-01");
        }

        @Test
        @DisplayName("idegen kamera-azonositora 'nem talalhato'")
        void unknownCameraRejected() {
            when(branchRepository.findByCompanyId(COMPANY_A)).thenReturn(List.of());
            assertThrows(ResourceNotFoundException.class,
                    () -> service.assertCameraAccessible("cam-foreign"));
        }
    }

    @Nested
    @DisplayName("findRecordingForViewing")
    class Viewing {

        @Test
        @DisplayName("nem letezo felvetel eseten NULL (a controller 404-et ad), nem kivetel")
        void missingRecordingReturnsNull() {
            when(recordingRepository.findById(RECORDING_ID)).thenReturn(Optional.empty());
            assertNull(service.findRecordingForViewing(RECORDING_ID));
            verify(accessLogRepository, never()).save(any());
        }

        @Test
        @DisplayName("sikeres megtekintes VIEW audit-bejegyzest ir")
        void viewWritesAuditLog() {
            when(recordingRepository.findById(RECORDING_ID)).thenReturn(Optional.of(recordingOf(BRANCH_ID)));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_A)));

            assertEquals(RECORDING_ID, service.findRecordingForViewing(RECORDING_ID).getId());
            verify(accessLogRepository).save(any());
        }

        @Test
        @DisplayName("VISELKEDES-MEGORZES: az audit-iras hibaja NEM bukatja el a fo muveletet")
        void auditFailureDoesNotBreakViewing() {
            when(recordingRepository.findById(RECORDING_ID)).thenReturn(Optional.of(recordingOf(BRANCH_ID)));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_A)));
            when(accessLogRepository.save(any())).thenThrow(new RuntimeException("audit DB down"));

            assertEquals(RECORDING_ID, service.findRecordingForViewing(RECORDING_ID).getId());
        }

        @Test
        @DisplayName("idegen tenant felvetelet nem adja ki")
        void foreignRecordingRejected() {
            when(recordingRepository.findById(RECORDING_ID)).thenReturn(Optional.of(recordingOf(BRANCH_ID)));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_B)));
            assertThrows(ResourceNotFoundException.class,
                    () -> service.findRecordingForViewing(RECORDING_ID));
        }
    }

    @Nested
    @DisplayName("filterAccessibleLinks")
    class LinkFiltering {

        private CameraTransactionLink linkWith(CameraRecording recording) {
            CameraTransactionLink link = new CameraTransactionLink();
            link.setRecording(recording);
            return link;
        }

        @Test
        @DisplayName("sajat tenant kapcsolata bent marad")
        void ownLinkKept() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_A)));
            assertEquals(1, service.filterAccessibleLinks(
                    List.of(linkWith(recordingOf(BRANCH_ID)))).size());
        }

        @Test
        @DisplayName("MULTI-TENANT: idegen tenant kapcsolata csendben kiesik")
        void foreignLinkFilteredOut() {
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_B)));
            assertTrue(service.filterAccessibleLinks(
                    List.of(linkWith(recordingOf(BRANCH_ID)))).isEmpty());
        }

        @Test
        @DisplayName("felvetel nelkuli kapcsolat kiesik (nem dob NPE-t)")
        void linkWithoutRecordingFilteredOut() {
            assertTrue(service.filterAccessibleLinks(List.of(linkWith(null))).isEmpty());
        }

        @Test
        @DisplayName("ures bemenetre ures eredmeny")
        void emptyInput() {
            assertTrue(service.filterAccessibleLinks(List.of()).isEmpty());
        }
    }

    @Nested
    @DisplayName("konfiguracio-kezeles (admin)")
    class ConfigAdmin {

        @Test
        @DisplayName("mentes elott tenant-guard fut")
        void saveChecksTenant() {
            CameraConfig cfg = new CameraConfig();
            cfg.setBranchId(BRANCH_ID);
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_B)));

            assertThrows(ResourceNotFoundException.class, () -> service.saveConfig(cfg));
            verify(cameraConfigRepository, never()).save(any());
        }

        @Test
        @DisplayName("MULTI-TENANT: idegen konfiguracio torlese tiltott, es NEM torol")
        void deleteChecksTenant() {
            CameraConfig cfg = new CameraConfig();
            cfg.setBranchId(BRANCH_ID);
            UUID configId = UUID.randomUUID();
            when(cameraConfigRepository.findById(configId)).thenReturn(Optional.of(cfg));
            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branchOf(COMPANY_B)));

            assertThrows(ResourceNotFoundException.class, () -> service.deleteConfig(configId));
            verify(cameraConfigRepository, never()).deleteById(any());
        }

        @Test
        @DisplayName("nem letezo konfiguracio torlese 'nem talalhato'")
        void deleteMissingConfig() {
            UUID configId = UUID.randomUUID();
            when(cameraConfigRepository.findById(configId)).thenReturn(Optional.empty());
            assertThrows(ResourceNotFoundException.class, () -> service.deleteConfig(configId));
        }
    }

    @Test
    @DisplayName("countLinkedTransactions a kapcsolatok szamat adja")
    void countLinkedTransactions() {
        when(linkRepository.findByRecordingId(RECORDING_ID))
                .thenReturn(List.of(new CameraTransactionLink(), new CameraTransactionLink()));
        assertEquals(2, service.countLinkedTransactions(RECORDING_ID));
        assertFalse(false);
    }
}

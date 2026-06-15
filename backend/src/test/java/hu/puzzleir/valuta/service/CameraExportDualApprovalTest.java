package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CameraExportRequest;
import hu.puzzleir.valuta.entity.CameraExportStatus;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CameraExportRequestRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.repository.CameraSegmentHashRepository;
import hu.puzzleir.valuta.repository.ChainOfCustodyRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

/**
 * Sprint 4 P2-C: CameraExport dual approval (4-eyes) tesztek.
 * v2.0 spec + Anti masterplan §12.4 ("dual approval" videó exporthoz).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class CameraExportDualApprovalTest {

    @Mock private CameraExportRequestRepository exportRepository;
    @Mock private CameraRecordingRepository recordingRepository;
    @Mock private CameraTransactionLinkRepository linkRepository;
    @Mock private ChainOfCustodyRepository custodyRepository;
    @Mock private CameraSegmentHashRepository hashRepository;
    @Mock private CameraStorageService storageService;
    @Mock private CameraEncryptionService encryptionService;
    @Mock private CameraHashChainService hashChainService;
    @Mock private hu.puzzleir.valuta.repository.BranchRepository branchRepository;

    @InjectMocks
    private CameraExportService exportService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID REQUEST_ID = UUID.randomUUID();

    private CameraExportRequest baseRequest;

    @BeforeEach
    void setUp() {
        when(exportRepository.save(any(CameraExportRequest.class))).thenAnswer(inv -> inv.getArgument(0));
        // IDOR-guard (audit 2026-06-15): a findRequest branch-ownership-check-et hív; saját cég → true.
        when(branchRepository.existsByIdAndCompanyId(any(), any())).thenReturn(true);

        baseRequest = CameraExportRequest.builder()
                .id(REQUEST_ID)
                .branchId(BRANCH_ID)
                .cameraId("CAM1")
                .periodFrom(LocalDateTime.now().minusDays(7))
                .periodTo(LocalDateTime.now())
                .reason("Hatósági megkeresés")
                .requestedBy("WORKER_REQ")
                .status(CameraExportStatus.REQUESTED)
                .requiresDualApproval(true)
                .build();
        when(exportRepository.findById(REQUEST_ID)).thenReturn(Optional.of(baseRequest));
    }

    private void setCurrentWorker(String workerCode) {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                1L, COMPANY_ID, BRANCH_ID, workerCode);
        TestingAuthenticationToken auth = new TestingAuthenticationToken(workerCode, "x", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("requiresDualApproval=true: 1. approver → AWAITING_SECOND_APPROVAL")
    void firstApprover_setsAwaitingSecond() {
        setCurrentWorker("WORKER_A");

        var result = exportService.approveExport(REQUEST_ID);

        assertThat(result.getStatus()).isEqualTo(CameraExportStatus.AWAITING_SECOND_APPROVAL);
        assertThat(result.getApprovedBy()).isEqualTo("WORKER_A");
        assertThat(result.getSecondApprovedBy()).isNull();
    }

    @Test
    @DisplayName("requiresDualApproval=true: 2. approver → APPROVED")
    void secondApprover_setsApproved() {
        baseRequest.setStatus(CameraExportStatus.AWAITING_SECOND_APPROVAL);
        baseRequest.setApprovedBy("WORKER_A");
        baseRequest.setApprovedAt(LocalDateTime.now().minusMinutes(5));
        setCurrentWorker("WORKER_B");

        var result = exportService.approveExportSecond(REQUEST_ID);

        assertThat(result.getStatus()).isEqualTo(CameraExportStatus.APPROVED);
        assertThat(result.getSecondApprovedBy()).isEqualTo("WORKER_B");
        assertThat(result.getApprovedBy()).isEqualTo("WORKER_A"); // marad az 1. approver
    }

    @Test
    @DisplayName("2. approver = requestedBy → ValidationException")
    void secondApprover_isRequestor_throws() {
        baseRequest.setStatus(CameraExportStatus.AWAITING_SECOND_APPROVAL);
        baseRequest.setApprovedBy("WORKER_A");
        setCurrentWorker("WORKER_REQ"); // a kérelmező

        assertThatThrownBy(() -> exportService.approveExportSecond(REQUEST_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem lehet a kérelmező");
    }

    @Test
    @DisplayName("2. approver = 1. approver → ValidationException")
    void secondApprover_isFirstApprover_throws() {
        baseRequest.setStatus(CameraExportStatus.AWAITING_SECOND_APPROVAL);
        baseRequest.setApprovedBy("WORKER_A");
        setCurrentWorker("WORKER_A"); // ugyanaz mint az 1. approver

        assertThatThrownBy(() -> exportService.approveExportSecond(REQUEST_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem lehet az 1. jóváhagyó");
    }

    @Test
    @DisplayName("2. approval rossz státuszon → ValidationException")
    void secondApproval_wrongStatus_throws() {
        baseRequest.setStatus(CameraExportStatus.REQUESTED); // még nem volt 1. approval
        setCurrentWorker("WORKER_B");

        assertThatThrownBy(() -> exportService.approveExportSecond(REQUEST_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("AWAITING_SECOND_APPROVAL");
    }

    @Test
    @DisplayName("requiresDualApproval=false: 1. approver → azonnal APPROVED (backward-compat)")
    void singleApproval_setsApprovedDirectly() {
        baseRequest.setRequiresDualApproval(false);
        setCurrentWorker("WORKER_A");

        var result = exportService.approveExport(REQUEST_ID);

        assertThat(result.getStatus()).isEqualTo(CameraExportStatus.APPROVED);
        assertThat(result.getApprovedBy()).isEqualTo("WORKER_A");
    }

    @Test
    @DisplayName("reject működik AWAITING_SECOND_APPROVAL státuszra is (2. approver visszadobja)")
    void reject_awaitingSecond_works() {
        baseRequest.setStatus(CameraExportStatus.AWAITING_SECOND_APPROVAL);
        baseRequest.setApprovedBy("WORKER_A");
        baseRequest.setApprovedAt(LocalDateTime.of(2026, 5, 13, 10, 0));
        setCurrentWorker("WORKER_B");

        var result = exportService.rejectExport(REQUEST_ID, "indok");

        assertThat(result.getStatus()).isEqualTo(CameraExportStatus.REJECTED);
        assertThat(result.getRejectionReason()).isEqualTo("indok");
        // Copilot P3 #578 follow-up: dual-approval flow-ban a reject NE írja felül az 1.
        // approver audit-fieldjeit. ApprovedBy/At változatlan, rejectedBy/At új mezők.
        assertThat(result.getApprovedBy()).as("1. approver audit data preserved").isEqualTo("WORKER_A");
        assertThat(result.getApprovedAt()).as("1. approval timestamp preserved").isNotNull();
        assertThat(result.getRejectedBy()).as("rejector recorded separately").isEqualTo("WORKER_B");
        assertThat(result.getRejectedAt()).as("reject timestamp recorded").isNotNull();
    }
}

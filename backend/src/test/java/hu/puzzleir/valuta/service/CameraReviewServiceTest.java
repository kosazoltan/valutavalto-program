package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.camera.CreateMarkRequest;
import hu.puzzleir.valuta.dto.camera.ReviewOverviewRowDto;
import hu.puzzleir.valuta.dto.camera.ReviewTransactionDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraReviewMark;
import hu.puzzleir.valuta.entity.CameraReviewStatus;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraReviewMarkRepository;
import hu.puzzleir.valuta.repository.CameraReviewStatusRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.mockStatic;

@ExtendWith(MockitoExtension.class)
class CameraReviewServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID FOREIGN_COMPANY_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID BRANCH_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID BRANCH_2_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");
    private static final LocalDate REVIEW_DATE = LocalDate.of(2026, 7, 10);

    @Mock private CameraReviewMarkRepository markRepository;
    @Mock private CameraReviewStatusRepository statusRepository;
    @Mock private CameraRecordingRepository recordingRepository;
    @Mock private CameraTransactionLinkRepository linkRepository;
    @Mock private BranchRepository branchRepository;

    private CameraReviewService service;

    @BeforeEach
    void setUp() {
        service = new CameraReviewService(markRepository, statusRepository, recordingRepository, linkRepository, branchRepository);
    }

    @Test
    void createMark_savesWithCurrentWorkerAndCompany() {
        CreateMarkRequest request = validCreateRequest();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID, COMPANY_ID, "B1")));
        when(markRepository.save(any(CameraReviewMark.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            CameraReviewMark saved = service.createMark(request);

            assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
            assertThat(saved.getBranchId()).isEqualTo(BRANCH_ID);
            assertThat(saved.getReviewDate()).isEqualTo(REVIEW_DATE);
            assertThat(saved.getCameraId()).isEqualTo("cam-1");
            assertThat(saved.getMarkTime()).isEqualTo(LocalTime.of(8, 5, 7));
            assertThat(saved.getCreatedByWorkerId()).isEqualTo(42L);
            assertThat(saved.getCreatedByWorkerCode()).isEqualTo("W42");
            assertThat(saved.isProblematic()).isFalse();
        }
    }

    @Test
    void createMark_rejectsForeignBranch() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID, FOREIGN_COMPANY_ID, "B1")));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            assertThatThrownBy(() -> service.createMark(validCreateRequest()))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(markRepository, never()).save(any());
        }
    }

    @Test
    void createMark_rejectsNullConditionFlag() {
        CreateMarkRequest request = validCreateRequest();
        request.setCurtainOk(null);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID, COMPANY_ID, "B1")));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            assertThatThrownBy(() -> service.createMark(request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Minden feltétel");
            verify(markRepository, never()).save(any());
        }
    }

    @Test
    void createMark_rejectsTooLongNote() {
        CreateMarkRequest request = validCreateRequest();
        request.setNote("x".repeat(501));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            assertThatThrownBy(() -> service.createMark(request))
                    .isInstanceOf(ValidationException.class)
                    .hasMessage("A megjegyzés legfeljebb 500 karakter lehet!");
            verify(markRepository, never()).save(any());
        }
    }

    @Test
    void deleteMark_rejectsNonCreator() {
        UUID markId = UUID.randomUUID();
        when(markRepository.findById(markId)).thenReturn(Optional.of(mark(markId, COMPANY_ID, BRANCH_ID, 42L, null, false)));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(43L, "W43", COMPANY_ID)) {
            assertThatThrownBy(() -> service.deleteMark(markId))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Csak a megjelölés létrehozója törölheti");
            verify(markRepository, never()).save(any());
        }
    }

    @Test
    void deleteMark_rejectsForeignCompany() {
        UUID markId = UUID.randomUUID();
        when(markRepository.findById(markId)).thenReturn(Optional.of(mark(markId, FOREIGN_COMPANY_ID, BRANCH_ID, 42L, null, false)));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            assertThatThrownBy(() -> service.deleteMark(markId))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(markRepository, never()).save(any());
        }
    }

    @Test
    void deleteMark_rejectsAlreadyDeleted() {
        UUID markId = UUID.randomUUID();
        when(markRepository.findById(markId)).thenReturn(Optional.of(mark(markId, COMPANY_ID, BRANCH_ID, 42L, LocalDateTime.now(), false)));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            assertThatThrownBy(() -> service.deleteMark(markId))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(markRepository, never()).save(any());
        }
    }

    @Test
    void deleteMark_softDeletesForCreator() {
        UUID markId = UUID.randomUUID();
        CameraReviewMark existing = mark(markId, COMPANY_ID, BRANCH_ID, 42L, null, false);
        when(markRepository.findById(markId)).thenReturn(Optional.of(existing));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            service.deleteMark(markId);

            ArgumentCaptor<CameraReviewMark> captor = ArgumentCaptor.forClass(CameraReviewMark.class);
            verify(markRepository).save(captor.capture());
            assertThat(captor.getValue().getDeletedAt()).isNotNull();
            assertThat(captor.getValue().getDeletedByWorkerId()).isEqualTo(42L);
        }
    }

    @Test
    void setReviewStatus_upsertsByCompanyBranchDate() {
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID, COMPANY_ID, "B1")));
        when(statusRepository.findByCompanyIdAndBranchIdAndReviewDate(COMPANY_ID, BRANCH_ID, REVIEW_DATE))
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(CameraReviewStatus.builder()
                        .companyId(COMPANY_ID)
                        .branchId(BRANCH_ID)
                        .reviewDate(REVIEW_DATE)
                        .reviewed(false)
                        .build()));
        when(statusRepository.save(any(CameraReviewStatus.class))).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            CameraReviewStatus created = service.setReviewStatus(BRANCH_ID, REVIEW_DATE, true);
            CameraReviewStatus updated = service.setReviewStatus(BRANCH_ID, REVIEW_DATE, false);

            assertThat(created.getCompanyId()).isEqualTo(COMPANY_ID);
            assertThat(created.getBranchId()).isEqualTo(BRANCH_ID);
            assertThat(created.getReviewDate()).isEqualTo(REVIEW_DATE);
            assertThat(created.getReviewed()).isTrue();
            assertThat(created.getReviewedByWorkerId()).isEqualTo(42L);
            assertThat(created.getReviewedByWorkerCode()).isEqualTo("W42");
            assertThat(created.getReviewedAt()).isNotNull();
            assertThat(updated.getReviewed()).isFalse();
            assertThat(updated.getReviewedByWorkerId()).isEqualTo(42L);
        }
    }

    @Test
    void overview_flagsProblematicAndReviewed() {
        Branch b1 = branch(BRANCH_ID, COMPANY_ID, "B1");
        Branch b2 = branch(BRANCH_2_ID, COMPANY_ID, "B2");
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(b1, b2));
        when(recordingRepository.findByBranchIdAndStartTimeBetween(BRANCH_ID, REVIEW_DATE.atStartOfDay(), REVIEW_DATE.plusDays(1).atStartOfDay()))
                .thenReturn(List.of(recording(BRANCH_ID, "cam-1", REVIEW_DATE.atTime(8, 0)), recording(BRANCH_ID, "cam-2", REVIEW_DATE.atTime(9, 0))));
        when(recordingRepository.findByBranchIdAndStartTimeBetween(BRANCH_2_ID, REVIEW_DATE.atStartOfDay(), REVIEW_DATE.plusDays(1).atStartOfDay()))
                .thenReturn(List.of(recording(BRANCH_2_ID, "cam-1", REVIEW_DATE.atTime(8, 0))));
        when(markRepository.findByCompanyIdAndReviewDateBetweenAndDeletedAtIsNull(COMPANY_ID, REVIEW_DATE, REVIEW_DATE))
                .thenReturn(List.of(
                        mark(UUID.randomUUID(), COMPANY_ID, BRANCH_ID, 42L, null, true),
                        mark(UUID.randomUUID(), COMPANY_ID, BRANCH_2_ID, 42L, null, false)
                ));
        when(statusRepository.findByCompanyIdAndReviewDateBetween(COMPANY_ID, REVIEW_DATE, REVIEW_DATE))
                .thenReturn(List.of(CameraReviewStatus.builder()
                        .companyId(COMPANY_ID)
                        .branchId(BRANCH_2_ID)
                        .reviewDate(REVIEW_DATE)
                        .reviewed(true)
                        .build()));

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            List<ReviewOverviewRowDto> rows = service.overview(REVIEW_DATE, REVIEW_DATE, null, false);
            List<ReviewOverviewRowDto> problematicOnly = service.overview(REVIEW_DATE, REVIEW_DATE, null, true);

            ReviewOverviewRowDto row1 = rows.stream().filter(row -> BRANCH_ID.equals(row.getBranchId())).findFirst().orElseThrow();
            ReviewOverviewRowDto row2 = rows.stream().filter(row -> BRANCH_2_ID.equals(row.getBranchId())).findFirst().orElseThrow();
            assertThat(row1.isProblematic()).isTrue();
            assertThat(row1.isReviewed()).isFalse();
            assertThat(row1.getRecordingCount()).isEqualTo(2);
            assertThat(row1.getMarkCount()).isEqualTo(1);
            assertThat(row2.isProblematic()).isFalse();
            assertThat(row2.isReviewed()).isTrue();
            assertThat(problematicOnly).extracting(ReviewOverviewRowDto::getBranchId).containsExactly(BRANCH_ID);
        }
    }

    @Test
    void listTransactionsPassesCurrentCompanyToRepository() {
        LocalDateTime start = REVIEW_DATE.atStartOfDay();
        LocalDateTime end = REVIEW_DATE.plusDays(1).atStartOfDay();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch(BRANCH_ID, COMPANY_ID, "B1")));
        when(linkRepository.findByBranchAndTimeRange(BRANCH_ID, COMPANY_ID, start, end)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> sec = mockSecurity(42L, "W42", COMPANY_ID)) {
            List<ReviewTransactionDto> transactions = service.listTransactions(BRANCH_ID, REVIEW_DATE);

            assertThat(transactions).isEmpty();
            verify(linkRepository).findByBranchAndTimeRange(BRANCH_ID, COMPANY_ID, start, end);
        }
    }

    private static MockedStatic<SecurityUtils> mockSecurity(Long workerId, String workerCode, UUID companyId) {
        MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class);
        sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
        sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(workerId);
        sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn(workerCode);
        return sec;
    }

    private CreateMarkRequest validCreateRequest() {
        CreateMarkRequest request = new CreateMarkRequest();
        request.setBranchId(BRANCH_ID);
        request.setReviewDate(REVIEW_DATE);
        request.setCameraId("cam-1");
        request.setMarkTime(LocalTime.of(8, 5, 7));
        request.setOpeningClosingOk(true);
        request.setInvoicesOk(true);
        request.setBreaksOk(true);
        request.setBoardOk(true);
        request.setCurtainOk(true);
        request.setNote("rendben");
        return request;
    }

    private CameraReviewMark mark(UUID id, UUID companyId, UUID branchId, Long creatorId, LocalDateTime deletedAt, boolean problematic) {
        return CameraReviewMark.builder()
                .id(id)
                .companyId(companyId)
                .branchId(branchId)
                .reviewDate(REVIEW_DATE)
                .cameraId("cam-1")
                .markTime(LocalTime.of(8, 5, 7))
                .openingClosingOk(true)
                .invoicesOk(true)
                .breaksOk(true)
                .boardOk(true)
                .curtainOk(!problematic)
                .createdByWorkerId(creatorId)
                .createdByWorkerCode("W42")
                .deletedAt(deletedAt)
                .build();
    }

    private CameraRecording recording(UUID branchId, String cameraId, LocalDateTime startTime) {
        return CameraRecording.builder()
                .id(UUID.randomUUID())
                .branchId(branchId)
                .cameraId(cameraId)
                .startTime(startTime)
                .build();
    }

    private Branch branch(UUID branchId, UUID companyId, String code) {
        return Branch.builder()
                .id(branchId)
                .code(code)
                .name("Branch " + code)
                .company(Company.builder().id(companyId).code("COMP").name("Company").build())
                .bankCode("BANK")
                .address("Addr")
                .city("City")
                .zipCode("0000")
                .build();
    }
}

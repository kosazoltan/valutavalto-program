package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.camera.CameraReviewMarkDto;
import hu.puzzleir.valuta.dto.camera.CreateMarkRequest;
import hu.puzzleir.valuta.dto.camera.ReviewOverviewRowDto;
import hu.puzzleir.valuta.dto.camera.ReviewStatusDto;
import hu.puzzleir.valuta.dto.camera.ReviewTransactionDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraReviewMark;
import hu.puzzleir.valuta.entity.CameraReviewStatus;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraReviewMarkRepository;
import hu.puzzleir.valuta.repository.CameraReviewStatusRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CameraReviewService {

    private final CameraReviewMarkRepository markRepository;
    private final CameraReviewStatusRepository statusRepository;
    private final CameraRecordingRepository recordingRepository;
    private final CameraTransactionLinkRepository linkRepository;
    private final BranchRepository branchRepository;

    @Transactional
    public CameraReviewMark createMark(CreateMarkRequest req) {
        validateCreateRequestHeader(req);
        validateNoteLength(req);
        requireOwnBranch(req.getBranchId());
        validateConditionFlags(req);

        CameraReviewMark mark = CameraReviewMark.builder()
                .companyId(SecurityUtils.getCurrentCompanyId())
                .branchId(req.getBranchId())
                .reviewDate(req.getReviewDate())
                .cameraId(req.getCameraId())
                .markTime(req.getMarkTime())
                .openingClosingOk(req.getOpeningClosingOk())
                .invoicesOk(req.getInvoicesOk())
                .breaksOk(req.getBreaksOk())
                .boardOk(req.getBoardOk())
                .curtainOk(req.getCurtainOk())
                .note(req.getNote())
                .createdByWorkerId(SecurityUtils.getCurrentWorkerId())
                .createdByWorkerCode(SecurityUtils.getCurrentWorkerCode())
                .build();
        return markRepository.save(mark);
    }

    @Transactional
    public void deleteMark(UUID markId) {
        if (markId == null) {
            throw new ResourceNotFoundException("Megjelölés nem található: null");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CameraReviewMark mark = markRepository.findById(markId)
                .filter(m -> companyId.equals(m.getCompanyId()) && m.getDeletedAt() == null)
                .orElseThrow(() -> new ResourceNotFoundException("Megjelölés nem található: " + markId));

        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        if (currentWorkerId == null || !currentWorkerId.equals(mark.getCreatedByWorkerId())) {
            throw new ValidationException("Csak a megjelölés létrehozója törölheti a megjelölést");
        }

        mark.setDeletedAt(LocalDateTime.now());
        mark.setDeletedByWorkerId(currentWorkerId);
        markRepository.save(mark);
    }

    @Transactional
    public CameraReviewStatus setReviewStatus(UUID branchId, LocalDate reviewDate, boolean reviewed) {
        if (reviewDate == null) {
            throw new ValidationException("Az átnézés napja kötelező");
        }
        requireOwnBranch(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CameraReviewStatus status = statusRepository
                .findByCompanyIdAndBranchIdAndReviewDate(companyId, branchId, reviewDate)
                .orElseGet(() -> CameraReviewStatus.builder()
                        .companyId(companyId)
                        .branchId(branchId)
                        .reviewDate(reviewDate)
                        .build());

        status.setReviewed(reviewed);
        status.setReviewedByWorkerId(SecurityUtils.getCurrentWorkerId());
        status.setReviewedByWorkerCode(SecurityUtils.getCurrentWorkerCode());
        status.setReviewedAt(LocalDateTime.now());
        return statusRepository.save(status);
    }

    @Transactional(readOnly = true)
    public ReviewStatusDto getReviewStatus(UUID branchId, LocalDate reviewDate) {
        if (reviewDate == null) {
            throw new ValidationException("Az átnézés napja kötelező");
        }
        requireOwnBranch(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return statusRepository.findByCompanyIdAndBranchIdAndReviewDate(companyId, branchId, reviewDate)
                .map(this::toStatusDto)
                .orElseGet(() -> ReviewStatusDto.builder().reviewed(false).build());
    }

    @Transactional(readOnly = true)
    public List<CameraReviewMarkDto> listMarks(UUID branchId, LocalDate reviewDate) {
        if (reviewDate == null) {
            throw new ValidationException("Az átnézés napja kötelező");
        }
        requireOwnBranch(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return markRepository
                .findByCompanyIdAndBranchIdAndReviewDateAndDeletedAtIsNullOrderByMarkTimeAsc(
                        companyId, branchId, reviewDate)
                .stream()
                .map(this::toMarkDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewTransactionDto> listTransactions(UUID branchId, LocalDate reviewDate) {
        if (reviewDate == null) {
            throw new ValidationException("A tranzakció napja kötelező");
        }
        requireOwnBranch(branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime start = reviewDate.atStartOfDay();
        LocalDateTime end = reviewDate.plusDays(1).atStartOfDay();
        return linkRepository.findByBranchAndTimeRange(branchId, companyId, start, end).stream()
                .map(this::toTransactionDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewOverviewRowDto> overview(LocalDate start, LocalDate end, UUID branchId, boolean onlyProblematic) {
        validateDateRange(start, end);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime startDateTime = start.atStartOfDay();
        LocalDateTime endExclusive = end.plusDays(1).atStartOfDay();

        List<Branch> branches = branchId == null
                ? branchRepository.findByCompanyId(companyId)
                : List.of(requireOwnBranch(branchId));

        List<CameraReviewMark> marks = markRepository.findByCompanyIdAndReviewDateBetweenAndDeletedAtIsNull(companyId, start, end);
        Map<BranchDateKey, Long> markCounts = marks.stream()
                .collect(Collectors.groupingBy(
                        mark -> new BranchDateKey(mark.getBranchId(), mark.getReviewDate()),
                        Collectors.counting()));
        Map<BranchDateKey, Boolean> problematicByBranchDate = marks.stream()
                .collect(Collectors.toMap(
                        mark -> new BranchDateKey(mark.getBranchId(), mark.getReviewDate()),
                        CameraReviewMark::isProblematic,
                        Boolean::logicalOr));
        Map<BranchDateKey, Boolean> reviewedByBranchDate = statusRepository
                .findByCompanyIdAndReviewDateBetween(companyId, start, end)
                .stream()
                .collect(Collectors.toMap(
                        status -> new BranchDateKey(status.getBranchId(), status.getReviewDate()),
                        status -> Boolean.TRUE.equals(status.getReviewed()),
                        Boolean::logicalOr));

        List<ReviewOverviewRowDto> rows = branches.stream()
                .flatMap(branch -> rowsForBranch(branch, startDateTime, endExclusive, markCounts,
                        problematicByBranchDate, reviewedByBranchDate).stream())
                .filter(row -> !onlyProblematic || row.isProblematic())
                .sorted(Comparator.comparing(ReviewOverviewRowDto::getDate).reversed()
                        .thenComparing(row -> Optional.ofNullable(row.getBranchCode()).orElse("")))
                .toList();
        return rows;
    }

    private List<ReviewOverviewRowDto> rowsForBranch(
            Branch branch,
            LocalDateTime startDateTime,
            LocalDateTime endExclusive,
            Map<BranchDateKey, Long> markCounts,
            Map<BranchDateKey, Boolean> problematicByBranchDate,
            Map<BranchDateKey, Boolean> reviewedByBranchDate) {
        Map<LocalDate, Long> recordingsByDate = new HashMap<>();
        for (CameraRecording recording : recordingRepository.findByBranchIdAndStartTimeBetween(branch.getId(), startDateTime, endExclusive)) {
            if (recording.getStartTime() == null) {
                continue;
            }
            LocalDate date = recording.getStartTime().toLocalDate();
            recordingsByDate.merge(date, 1L, Long::sum);
        }

        return recordingsByDate.entrySet().stream()
                .map(entry -> {
                    BranchDateKey key = new BranchDateKey(branch.getId(), entry.getKey());
                    return ReviewOverviewRowDto.builder()
                            .branchId(branch.getId())
                            .branchCode(branch.getCode())
                            .branchName(branch.getName())
                            .date(entry.getKey())
                            .recordingCount(Math.toIntExact(entry.getValue()))
                            .markCount(Math.toIntExact(markCounts.getOrDefault(key, 0L)))
                            .reviewed(Boolean.TRUE.equals(reviewedByBranchDate.get(key)))
                            .problematic(Boolean.TRUE.equals(problematicByBranchDate.get(key)))
                            .build();
                })
                .toList();
    }

    private void validateCreateRequestHeader(CreateMarkRequest req) {
        if (req == null || req.getBranchId() == null || req.getReviewDate() == null
                || req.getMarkTime() == null || req.getCameraId() == null || req.getCameraId().isBlank()) {
            throw new ValidationException("Hiányzó megjelölés-adat (iroda/nap/idő/kamera kötelező)");
        }
    }

    private void validateConditionFlags(CreateMarkRequest req) {
        if (req.getOpeningClosingOk() == null || req.getInvoicesOk() == null
                || req.getBreaksOk() == null || req.getBoardOk() == null || req.getCurtainOk() == null) {
            throw new ValidationException("Minden feltétel-jelölés kötelező (rendben / nincs rendben)");
        }
    }

    private void validateNoteLength(CreateMarkRequest req) {
        if (req.getNote() != null && req.getNote().length() > 500) {
            throw new ValidationException("A megjegyzés legfeljebb 500 karakter lehet!");
        }
    }

    private void validateDateRange(LocalDate start, LocalDate end) {
        if (start == null || end == null) {
            throw new ValidationException("A kezdő és záró dátum kötelező");
        }
        if (end.isBefore(start)) {
            throw new ValidationException("A záró dátum nem lehet korábbi a kezdő dátumnál");
        }
    }

    private Branch requireOwnBranch(UUID branchId) {
        if (branchId == null) {
            throw new ResourceNotFoundException("Iroda nem található: null");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        if (branch.getCompany() == null || !companyId.equals(branch.getCompany().getId())) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
        return branch;
    }

    private CameraReviewMarkDto toMarkDto(CameraReviewMark mark) {
        return CameraReviewMarkDto.builder()
                .id(mark.getId())
                .branchId(mark.getBranchId())
                .reviewDate(mark.getReviewDate())
                .cameraId(mark.getCameraId())
                .markTime(mark.getMarkTime())
                .openingClosingOk(mark.getOpeningClosingOk())
                .invoicesOk(mark.getInvoicesOk())
                .breaksOk(mark.getBreaksOk())
                .boardOk(mark.getBoardOk())
                .curtainOk(mark.getCurtainOk())
                .note(mark.getNote())
                .createdByWorkerId(mark.getCreatedByWorkerId())
                .createdByWorkerCode(mark.getCreatedByWorkerCode())
                .createdAt(mark.getCreatedAt())
                .problematic(mark.isProblematic())
                .build();
    }

    private ReviewStatusDto toStatusDto(CameraReviewStatus status) {
        return ReviewStatusDto.builder()
                .reviewed(Boolean.TRUE.equals(status.getReviewed()))
                .reviewedByWorkerId(status.getReviewedByWorkerId())
                .reviewedByWorkerCode(status.getReviewedByWorkerCode())
                .reviewedAt(status.getReviewedAt())
                .build();
    }

    private ReviewTransactionDto toTransactionDto(CameraTransactionLink link) {
        CameraRecording recording = link.getRecording();
        return ReviewTransactionDto.builder()
                .id(link.getId())
                .transactionId(link.getTransactionId())
                .receiptNumber(link.getReceiptNumber())
                .transactionTime(link.getTransactionTime())
                .frameOffsetSeconds(link.getFrameOffsetSeconds())
                .cameraId(recording.getCameraId())
                .recordingId(recording.getId())
                .build();
    }

    private record BranchDateKey(UUID branchId, LocalDate date) {
        private BranchDateKey {
            Objects.requireNonNull(branchId, "branchId");
            Objects.requireNonNull(date, "date");
        }
    }
}

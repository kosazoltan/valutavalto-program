package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.camera.CameraReviewMarkDto;
import hu.puzzleir.valuta.dto.camera.CreateMarkRequest;
import hu.puzzleir.valuta.dto.camera.ReviewOverviewRowDto;
import hu.puzzleir.valuta.dto.camera.ReviewStatusDto;
import hu.puzzleir.valuta.dto.camera.ReviewTransactionDto;
import hu.puzzleir.valuta.dto.camera.SetReviewStatusRequest;
import hu.puzzleir.valuta.entity.CameraReviewMark;
import hu.puzzleir.valuta.entity.CameraReviewStatus;
import hu.puzzleir.valuta.service.CameraReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@RestController
@RequestMapping("/api/v1/camera/review")
@RequiredArgsConstructor
public class CameraReviewController {

    private static final String REVIEW_AUTH = "hasAnyAuthority('COMPLIANCE_OFFICER', 'REGIONAL_MANAGER', 'SYSTEM_ADMIN')";

    private final CameraReviewService service;

    @GetMapping("/overview")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<List<ReviewOverviewRowDto>> overview(
            @RequestParam LocalDate start,
            @RequestParam LocalDate end,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(defaultValue = "false") boolean onlyProblematic) {
        return ResponseEntity.ok(service.overview(start, end, branchId, onlyProblematic));
    }

    @GetMapping("/marks")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<List<CameraReviewMarkDto>> listMarks(
            @RequestParam UUID branchId,
            @RequestParam LocalDate date) {
        return ResponseEntity.ok(service.listMarks(branchId, date));
    }

    @PostMapping("/marks")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<CameraReviewMarkDto> createMark(@RequestBody CreateMarkRequest request) {
        return ResponseEntity.ok(toMarkDto(service.createMark(request)));
    }

    @DeleteMapping("/marks/{id}")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<Void> deleteMark(@PathVariable UUID id) {
        service.deleteMark(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/status")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<ReviewStatusDto> getStatus(
            @RequestParam UUID branchId,
            @RequestParam LocalDate date) {
        return ResponseEntity.ok(service.getReviewStatus(branchId, date));
    }

    @PutMapping("/status")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<ReviewStatusDto> setStatus(@RequestBody SetReviewStatusRequest request) {
        CameraReviewStatus status = service.setReviewStatus(
                request.getBranchId(),
                request.getReviewDate(),
                request.isReviewed());
        return ResponseEntity.ok(toStatusDto(status));
    }

    @GetMapping("/transactions")
    @PreAuthorize(REVIEW_AUTH)
    public ResponseEntity<List<ReviewTransactionDto>> listTransactions(
            @RequestParam UUID branchId,
            @RequestParam LocalDate date) {
        return ResponseEntity.ok(service.listTransactions(branchId, date));
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
}

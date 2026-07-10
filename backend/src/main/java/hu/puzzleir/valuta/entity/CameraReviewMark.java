package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(name = "camera_review_mark")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CameraReviewMark {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "review_date", nullable = false)
    private LocalDate reviewDate;

    @Column(name = "camera_id", nullable = false, length = 50)
    private String cameraId;

    @Column(name = "mark_time", nullable = false)
    private LocalTime markTime;

    @Column(name = "opening_closing_ok", nullable = false)
    private Boolean openingClosingOk;

    @Column(name = "invoices_ok", nullable = false)
    private Boolean invoicesOk;

    @Column(name = "breaks_ok", nullable = false)
    private Boolean breaksOk;

    @Column(name = "board_ok", nullable = false)
    private Boolean boardOk;

    @Column(name = "curtain_ok", nullable = false)
    private Boolean curtainOk;

    @Column(length = 500)
    private String note;

    @Column(name = "created_by_worker_id", nullable = false)
    private Long createdByWorkerId;

    @Column(name = "created_by_worker_code", length = 50)
    private String createdByWorkerCode;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "deleted_by_worker_id")
    private Long deletedByWorkerId;

    @Transient
    public boolean isProblematic() {
        return !(Boolean.TRUE.equals(openingClosingOk)
                && Boolean.TRUE.equals(invoicesOk)
                && Boolean.TRUE.equals(breaksOk)
                && Boolean.TRUE.equals(boardOk)
                && Boolean.TRUE.equals(curtainOk));
    }
}

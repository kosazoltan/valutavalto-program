package hu.puzzleir.valuta.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "camera_review_status", uniqueConstraints = @UniqueConstraint(
        name = "uq_crs_company_branch_date",
        columnNames = {"company_id", "branch_id", "review_date"}
))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CameraReviewStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "review_date", nullable = false)
    private LocalDate reviewDate;

    @Column(nullable = false)
    @Builder.Default
    private Boolean reviewed = Boolean.FALSE;

    @Column(name = "reviewed_by_worker_id")
    private Long reviewedByWorkerId;

    @Column(name = "reviewed_by_worker_code", length = 50)
    private String reviewedByWorkerCode;

    @Column(name = "reviewed_at")
    private LocalDateTime reviewedAt;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

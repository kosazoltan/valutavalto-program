package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Kamera export kérelem — 4-eyes jóváhagyással.
 *
 * Életciklus: REQUESTED → APPROVED → EXPORTING → COMPLETED / REJECTED / FAILED
 *
 * Az export kérelmet a kérelmező indítja, de a jóváhagyónak
 * egy másik személy (supervisor/compliance) kell legyen.
 */
@Entity
@Table(name = "camera_export_request", indexes = {
    @Index(name = "idx_camera_export_branch", columnList = "branch_id"),
    @Index(name = "idx_camera_export_status", columnList = "status"),
    @Index(name = "idx_camera_export_created", columnList = "created_at")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CameraExportRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "camera_id", length = 50)
    private String cameraId;

    /** Export időszak kezdete */
    @Column(name = "period_from", nullable = false)
    private LocalDateTime periodFrom;

    /** Export időszak vége */
    @Column(name = "period_to", nullable = false)
    private LocalDateTime periodTo;

    /** Indoklás (kötelező mező) */
    @Column(name = "reason", nullable = false, columnDefinition = "TEXT")
    private String reason;

    /** Kapcsolódó ügy/bizonylatszám (opcionális) */
    @Column(name = "reference_number", length = 100)
    private String referenceNumber;

    /** Állapot */
    // Codex P1 #570 fix: V220 bevezette az AWAITING_SECOND_APPROVAL (24 chars) enum
    // értéket, de a length=20 túl rövid volt → production value-too-long crash.
    // V223 a DB oszlopot VARCHAR(30)-ra szélesíti, entity length=30 ehhez igazítva.
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    @Builder.Default
    private CameraExportStatus status = CameraExportStatus.REQUESTED;

    // === Kérelmező ===
    @Column(name = "requested_by", nullable = false, length = 100)
    private String requestedBy;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // === Jóváhagyó (4-eyes — 1. szint) ===
    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    // Codex P2 #570 fix (V223): külön rejectedBy/rejectedAt audit oszlopok, hogy a
    // dual-approval flow-ban (1. approver már megvolt) a reject NE írja felül az
    // approved_by/approved_at audit data-t.
    @Column(name = "rejected_by", length = 100)
    private String rejectedBy;

    @Column(name = "rejected_at")
    private LocalDateTime rejectedAt;

    // === Sprint 4 (P2-C): 2. szintű jóváhagyás (dual approval) ===
    /** Igényel-e 2. jóváhagyót (default true a hatósági export-hoz). */
    @Column(name = "requires_dual_approval", nullable = false)
    @Builder.Default
    private Boolean requiresDualApproval = true;

    /** 2. jóváhagyó worker code (NEM egyezhet sem requestedBy-val, sem approvedBy-val). */
    @Column(name = "second_approved_by", length = 100)
    private String secondApprovedBy;

    @Column(name = "second_approved_at")
    private LocalDateTime secondApprovedAt;

    // === Export eredmény ===
    @Column(name = "export_path", length = 500)
    private String exportPath;

    @Column(name = "export_size_bytes")
    private Long exportSizeBytes;

    @Column(name = "manifest_hash", length = 64)
    private String manifestHash;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;
}

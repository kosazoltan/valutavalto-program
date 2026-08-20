package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Esti zárás szinkronizáció napló.
 *
 * Legacy: FTP-n küldött ESTIZAR bináris csomag → modern REST API szinkronizáció.
 */
@Entity
@Table(name = "evening_sync_log", indexes = {
    @Index(name = "idx_evening_sync_branch_date", columnList = "branch_id, sync_date")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EveningSyncLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "sync_date", nullable = false)
    private LocalDate syncDate;

    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "package_checksum", length = 128)
    private String packageChecksum;

    @Column(name = "attempt_count", nullable = false)
    @Builder.Default
    private Integer attemptCount = 0;

    @Column(name = "last_attempt_at")
    private LocalDateTime lastAttemptAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    /**
     * FK-091: true, ha a sikeresnek jelölt sor a HQ-küldés vészkijáratán
     * (helyi artifact) keresztül készült, nem valódi HQ HTTP 2xx válaszból.
     */
    @Column(name = "is_bridged", nullable = false)
    @Builder.Default
    private Boolean isBridged = Boolean.FALSE;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

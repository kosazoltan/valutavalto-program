package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Dictionary;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Sztornó jóváhagyás entity.
 * Napi sztornó limit felett supervisor jóváhagyás szükséges.
 */
@Entity
@Table(name = "storno_approval", indexes = {
    @Index(name = "idx_storno_approval_transaction", columnList = "transaction_id"),
    @Index(name = "idx_storno_approval_worker", columnList = "worker_id"),
    @Index(name = "idx_storno_approval_branch", columnList = "branch_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StornoApproval {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Sztornózandó tranzakció
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    /**
     * Kérelmező pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;

    /**
     * Iroda
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Napi sztornó száma a kérés pillanatában
     */
    @Column(name = "daily_storno_count", nullable = false)
    private Integer dailyStornoCount;

    /**
     * Jóváhagyási státusz (Dictionary: STORNO_APPROVAL_STATUS)
     * Értékek: PENDING, APPROVED, REJECTED
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approval_status_did")
    private Dictionary approvalStatus;

    /**
     * Sztornó kérés oka
     */
    @Column(name = "request_reason", nullable = false, length = 500)
    private String requestReason;

    /**
     * Elutasítás indoka
     */
    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    /**
     * Jóváhagyó supervisor
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by_worker_id")
    private Worker approvedByWorker;

    /**
     * Jóváhagyás időpontja
     */
    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

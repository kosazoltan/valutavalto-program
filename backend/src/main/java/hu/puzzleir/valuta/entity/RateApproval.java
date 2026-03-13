package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyam engedélyezés entity.
 *
 * Legacy: ratectrl.dll — az értéktár kontrollálja a pénztárak árfolyamait.
 * A pénztárak NEM változtathatnak árfolyamot az értéktár engedélye nélkül.
 */
@Entity
@Table(name = "rate_approval", indexes = {
    @Index(name = "idx_rate_approval_branch", columnList = "branch_id"),
    @Index(name = "idx_rate_approval_status", columnList = "status")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateApproval {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "old_buy_rate", precision = 12, scale = 4)
    private BigDecimal oldBuyRate;

    @Column(name = "old_sell_rate", precision = 12, scale = 4)
    private BigDecimal oldSellRate;

    @Column(name = "new_buy_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal newBuyRate;

    @Column(name = "new_sell_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal newSellRate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private RateApprovalStatus status = RateApprovalStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by")
    private Worker requestedByWorker;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    private Worker approvedByWorker;

    @Column(name = "requested_at", nullable = false)
    @Builder.Default
    private LocalDateTime requestedAt = LocalDateTime.now();

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(length = 500)
    private String reason;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

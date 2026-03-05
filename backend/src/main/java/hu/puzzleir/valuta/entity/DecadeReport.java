package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Dekádjelentés (10 napos összesítő).
 * Minden hónap 3 dekádra oszlik: 1-10, 11-20, 21-hó vége.
 * Évenként max 36 dekád (12 hónap × 3).
 */
@Entity
@Table(name = "decade_report", indexes = {
    @Index(name = "idx_decade_report_branch", columnList = "branch_id"),
    @Index(name = "idx_decade_report_year", columnList = "year")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_decade_report_branch_year_decade",
                      columnNames = {"branch_id", "year", "decade"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DecadeReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(nullable = false)
    private Integer year;

    /** Dekád sorszám: 1-36 (hónap * 3 - 2, hónap * 3 - 1, hónap * 3) */
    @Column(nullable = false)
    private Integer decade;

    @Column(name = "total_buy_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    @Column(name = "total_sell_huf", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    @Column(name = "total_handling_fee", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalHandlingFee = BigDecimal.ZERO;

    @Column(name = "transaction_count", nullable = false)
    @Builder.Default
    private Integer transactionCount = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private DecadeReportStatus status = DecadeReportStatus.DRAFT;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @Column(name = "closed_by")
    private Long closedBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum DecadeReportStatus {
        DRAFT, CLOSED
    }
}

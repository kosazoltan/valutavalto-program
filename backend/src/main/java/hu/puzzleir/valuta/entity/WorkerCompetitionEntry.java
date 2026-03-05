package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pénztáros verseny bejegyzés — egy pénztáros teljesítménye egy versenyben.
 */
@Entity
@Table(name = "worker_competition_entry", indexes = {
    @Index(name = "idx_comp_entry_competition", columnList = "competition_id"),
    @Index(name = "idx_comp_entry_worker", columnList = "worker_id")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_comp_entry",
                      columnNames = {"competition_id", "worker_id"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkerCompetitionEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "competition_id", nullable = false)
    private WorkerCompetition competition;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "total_volume", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal totalVolume = BigDecimal.ZERO;

    @Column(name = "transaction_count", nullable = false)
    @Builder.Default
    private Integer transactionCount = 0;

    @Column(precision = 18, scale = 4, nullable = false)
    @Builder.Default
    private BigDecimal score = BigDecimal.ZERO;

    @Column(name = "rank")
    private Integer rank;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

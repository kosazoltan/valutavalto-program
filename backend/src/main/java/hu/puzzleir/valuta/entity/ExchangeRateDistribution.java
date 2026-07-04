package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyam elosztás entity - nyomon követi, melyik pénztár kapta meg az árfolyamot.
 *
 * Legacy: ARFTMK modul - IRQ polling alapú árfolyam szinkronizáció a pénztáraknak.
 * Az új rendszerben REST API + WebSocket alapú push mechanizmus helyettesíti.
 */
@Entity
@Table(name = "exchange_rate_distribution", indexes = {
    @Index(name = "idx_erd_master", columnList = "master_rate_id"),
    @Index(name = "idx_erd_branch", columnList = "branch_id"),
    @Index(name = "idx_erd_status", columnList = "status")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExchangeRateDistribution {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "master_rate_id", nullable = false)
    private UUID masterRateId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "exchange_rate_id")
    private Long exchangeRateId;

    @Column(name = "distributed_at", nullable = false)
    @Builder.Default
    private LocalDateTime distributedAt = LocalDateTime.now();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private DistributionStatus status = DistributionStatus.PENDING;

    @Column(name = "acknowledged_at")
    private LocalDateTime acknowledgedAt;

    @Column(name = "printed_at")
    private LocalDateTime printedAt;

    @Column(name = "printed_by")
    private Long printedBy;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    public enum DistributionStatus {
        PENDING, DISTRIBUTED, ACKNOWLEDGED, FAILED
    }
}

package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Fiók státusz monitoring — locserver központi szerver.
 * Figyeli az alárendelt fiókok heartbeat-jét, szinkronizációját és napi forgalmát.
 */
@Entity
@Table(name = "branch_status")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BranchStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false, unique = true)
    private UUID branchId;

    @Column(name = "last_heartbeat")
    private LocalDateTime lastHeartbeat;

    @Column(name = "last_sync")
    private LocalDateTime lastSync;

    @Column(name = "is_online", nullable = false)
    private Boolean isOnline;

    @Column(name = "last_transaction_at")
    private LocalDateTime lastTransactionAt;

    @Column(name = "daily_transaction_count", nullable = false)
    private Integer dailyTransactionCount;

    @Column(name = "daily_volume_huf", nullable = false, precision = 18, scale = 2)
    private BigDecimal dailyVolumeHuf;

    @Column(name = "open_alerts", nullable = false)
    private Integer openAlerts;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (isOnline == null) isOnline = false;
        if (dailyTransactionCount == null) dailyTransactionCount = 0;
        if (dailyVolumeHuf == null) dailyVolumeHuf = BigDecimal.ZERO;
        if (openAlerts == null) openAlerts = 0;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

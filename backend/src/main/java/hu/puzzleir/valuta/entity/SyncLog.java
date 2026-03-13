package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import hu.puzzleir.valuta.entity.Branch;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * SyncLog entity — szinkronizáció napló.
 */
@Entity
@Table(name = "sync_log")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SyncLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Enumerated(EnumType.STRING)
    @Column(name = "sync_type", nullable = false, length = 20)
    private SyncType syncType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    @Builder.Default
    private SyncDirection direction = SyncDirection.DOWN;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private SyncStatus status = SyncStatus.PENDING;

    @Column(name = "started_at", nullable = false)
    @Builder.Default
    private LocalDateTime startedAt = LocalDateTime.now();

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "record_count")
    @Builder.Default
    private Integer recordCount = 0;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    public enum SyncType {
        RATES, TRANSACTIONS, INVENTORY, CLOSING, FULL
    }

    public enum SyncDirection {
        UP, DOWN
    }

    public enum SyncStatus {
        PENDING, RUNNING, COMPLETED, FAILED
    }
}

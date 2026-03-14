package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Inbox event entity for idempotency deduplication.
 */
@Entity
@Table(name = "sync_inbox")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncInboxEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "idempotency_key", nullable = false, unique = true, length = 120)
    private String idempotencyKey;

    @Column(name = "source_node_id", nullable = false, length = 100)
    private String sourceNodeId;

    @Column(name = "event_type", nullable = false, length = 100)
    private String eventType;

    @Column(name = "payload_hash", nullable = false, length = 128)
    private String payloadHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private SyncInboxStatus status = SyncInboxStatus.RECEIVED;

    @Column(name = "received_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime receivedAt = LocalDateTime.now();

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    public enum SyncInboxStatus {
        RECEIVED,
        PROCESSED,
        FAILED,
        DUPLICATE
    }
}

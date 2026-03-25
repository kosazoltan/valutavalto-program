package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "camera_transaction_link", indexes = {
    @Index(name = "idx_camera_tx_link_receipt", columnList = "receipt_number"),
    @Index(name = "idx_camera_tx_link_tx", columnList = "transaction_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CameraTransactionLink {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recording_id", nullable = false)
    private CameraRecording recording;

    @Column(name = "transaction_id")
    private Long transactionId;

    @Column(name = "receipt_number", length = 50)
    private String receiptNumber;

    @Column(name = "transaction_time", nullable = false)
    private LocalDateTime transactionTime;

    @Column(name = "frame_offset_seconds")
    private Integer frameOffsetSeconds;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

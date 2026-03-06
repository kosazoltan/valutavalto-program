package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "camera_access_log")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CameraAccessLog {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recording_id")
    private CameraRecording recording;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(nullable = false, length = 30)
    private String action; // VIEW, EXPORT, DELETE

    @Column(name = "ip_address", length = 45)
    private String ipAddress;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

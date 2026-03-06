package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "camera_recording", indexes = {
    @Index(name = "idx_camera_recording_branch_date", columnList = "branch_id, start_time"),
    @Index(name = "idx_camera_recording_expires", columnList = "expires_at")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CameraRecording {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "camera_id", nullable = false, length = 50)
    private String cameraId;

    @Column(name = "start_time", nullable = false)
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    @Column(name = "local_file_path", length = 500)
    private String localFilePath;

    @Column(name = "server_file_path", length = 500)
    private String serverFilePath;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "uploaded_to_server")
    @Builder.Default
    private Boolean uploadedToServer = false;

    @Column(name = "upload_attempts")
    @Builder.Default
    private Integer uploadAttempts = 0;

    @Column(name = "expires_at", nullable = false)
    private LocalDate expiresAt;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private RecordingStatus status = RecordingStatus.RECORDING;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum RecordingStatus {
        RECORDING, COMPLETED, UPLOADED, EXPIRED, ERROR
    }
}

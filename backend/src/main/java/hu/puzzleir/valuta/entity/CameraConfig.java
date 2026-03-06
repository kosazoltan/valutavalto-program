package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "camera_config", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"branch_id", "camera_id"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CameraConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "camera_id", nullable = false, length = 50)
    private String cameraId;

    @Column(name = "camera_name", length = 100)
    private String cameraName;

    @Column(name = "device_index")
    @Builder.Default
    private Integer deviceIndex = 0;

    @Column(name = "resolution_width")
    @Builder.Default
    private Integer resolutionWidth = 640;

    @Column(name = "resolution_height")
    @Builder.Default
    private Integer resolutionHeight = 480;

    @Builder.Default
    private Integer fps = 5;

    @Column(name = "jpeg_quality")
    @Builder.Default
    private Integer jpegQuality = 70;

    @Column(name = "local_storage_path", length = 500)
    private String localStoragePath;

    @Builder.Default
    private Boolean enabled = true;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

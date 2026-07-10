package hu.puzzleir.valuta.dto.camera;

import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CameraStatusDto {
    private String cameraId;
    private String cameraName;
    private UUID branchId;
    private boolean recording;
    private boolean connected;
    private long totalStorageBytes;
    private int recordingsCount;
    private String currentSegmentFile;
    private boolean frozen;
    private LocalDateTime lastFreshFrameAt;
}

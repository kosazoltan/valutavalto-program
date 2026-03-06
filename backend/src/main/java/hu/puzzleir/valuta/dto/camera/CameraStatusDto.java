package hu.puzzleir.valuta.dto.camera;

import lombok.*;
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
}

package hu.puzzleir.valuta.dto.camera;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecordingMetadataDto {
    private UUID id;
    private UUID branchId;
    private String cameraId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Long fileSizeBytes;
    private boolean uploadedToServer;
    private LocalDate expiresAt;
    private String status;
    private int linkedTransactions;
}

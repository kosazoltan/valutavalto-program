package hu.puzzleir.valuta.dto.camera;

import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecordingSearchDto {
    private UUID branchId;
    private String cameraId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private String receiptNumber;
}

package hu.puzzleir.valuta.dto.ftpsync;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class FtpSyncLogDto {
    private UUID id;
    private UUID branchId;
    private String direction;
    private String fileName;
    private String status;
    private Long fileSizeBytes;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private String errorMessage;
}

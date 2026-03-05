package hu.puzzleir.valuta.dto.sync;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SyncLogDto {
    private UUID id;
    private UUID branchId;
    private String syncType;
    private String direction;
    private String status;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private Integer recordCount;
    private String errorMessage;
}

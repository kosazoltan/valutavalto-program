package hu.puzzleir.valuta.dto.sync;

import lombok.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SyncStatusDto {
    private UUID branchId;
    private Map<String, LocalDateTime> lastSyncTimes;
}

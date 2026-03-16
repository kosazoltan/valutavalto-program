package hu.puzzleir.valuta.dto.led;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * LED kijelző valós idejű státusz DTO.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class LedDisplayStatusDto {
    private UUID branchId;
    private String branchName;
    private boolean connected;
    private LocalDateTime lastRefresh;
    private String lastError;
}

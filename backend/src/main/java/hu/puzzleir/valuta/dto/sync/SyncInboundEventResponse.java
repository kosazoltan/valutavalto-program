package hu.puzzleir.valuta.dto.sync;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncInboundEventResponse {

    private String idempotencyKey;
    private String eventType;
    private String status;
    private boolean duplicate;
    private LocalDateTime processedAt;
    private String message;
}

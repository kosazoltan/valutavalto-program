package hu.puzzleir.valuta.dto.polling;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Polling állapot DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PollingStatusDto {
    private LocalDateTime lastPollTime;
    private boolean lastPollSuccess;
    private String lastPollError;
    private int lastPollUpdatedCount;
}

package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Esti zárás szinkronizáció eredmény.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DataSyncResult {
    private boolean success;
    private String message;
    private int attemptCount;
    private LocalDateTime completedAt;
    private String checksum;

    public static DataSyncResult success(String checksum) {
        return DataSyncResult.builder()
                .success(true)
                .message("Adatcsomag sikeresen elküldve a központnak")
                .completedAt(LocalDateTime.now())
                .checksum(checksum)
                .build();
    }

    public static DataSyncResult failure(String message, int attemptCount) {
        return DataSyncResult.builder()
                .success(false)
                .message(message)
                .attemptCount(attemptCount)
                .build();
    }
}

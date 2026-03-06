package hu.puzzleir.valuta.dto.ftpsync;

import lombok.*;

/**
 * FTP szinkronizáció eredmény.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class FtpSyncResultDto {
    private boolean success;
    private String message;
    private String fileName;
    private Long fileSizeBytes;
    private FtpSyncLogDto syncLog;
}

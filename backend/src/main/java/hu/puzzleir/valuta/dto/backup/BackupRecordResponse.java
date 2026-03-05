package hu.puzzleir.valuta.dto.backup;

import hu.puzzleir.valuta.entity.BackupStatus;
import hu.puzzleir.valuta.entity.BackupType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class BackupRecordResponse {
    private UUID id;
    private BackupType backupType;
    private BackupStatus status;
    private String filePath;
    private Long fileSizeBytes;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private String createdBy;
}

package hu.puzzleir.valuta.dto.backup;

import hu.puzzleir.valuta.entity.BackupType;
import lombok.Data;

@Data
public class CreateBackupRequest {
    private BackupType type;
}

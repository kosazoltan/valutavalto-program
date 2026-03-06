package hu.puzzleir.valuta.dto.backup;

import hu.puzzleir.valuta.entity.BackupType;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateBackupRequest {
    @NotNull(message = "Backup típus kötelező (FULL/INCREMENTAL)")
    private BackupType type;
}

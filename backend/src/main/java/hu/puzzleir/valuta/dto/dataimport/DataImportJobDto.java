package hu.puzzleir.valuta.dto.dataimport;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DataImportJobDto {
    private UUID id;
    private UUID branchId;
    private String importType;
    private String status;
    private String sourceType;
    private String sourceFile;
    private Integer totalRecords;
    private Integer importedRecords;
    private Integer failedRecords;
    private String errorLog;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private LocalDateTime createdAt;
}

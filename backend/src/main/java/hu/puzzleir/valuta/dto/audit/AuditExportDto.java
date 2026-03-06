package hu.puzzleir.valuta.dto.audit;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Audit log export DTO — CSV export soraihoz.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditExportDto {
    private String id;
    private String action;
    private String entityType;
    private String entityId;
    private String userId;
    private String userName;
    private String branchId;
    private String branchName;
    private String changes;
    private String oldValue;
    private String newValue;
    private String reason;
    private String ipAddress;
    private LocalDateTime createdAt;
}

package hu.puzzleir.valuta.dto.audit;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Audit log bejegyzés DTO — frontend számára.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditLogEntryDto {
    private UUID id;
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
    private String userAgent;
    private LocalDateTime createdAt;
}

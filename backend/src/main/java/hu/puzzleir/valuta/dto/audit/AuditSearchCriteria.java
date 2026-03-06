package hu.puzzleir.valuta.dto.audit;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Audit napló keresési feltételek.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AuditSearchCriteria {
    private LocalDateTime dateFrom;
    private LocalDateTime dateTo;
    private String workerId;
    private String entityType;
    private String action;
    private String keyword;
}

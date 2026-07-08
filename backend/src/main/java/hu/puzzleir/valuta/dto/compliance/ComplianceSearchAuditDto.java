package hu.puzzleir.valuta.dto.compliance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/** FS-11 S2b: keresés-audit válasz — criteria deserializálva, snapshot nélkül. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComplianceSearchAuditDto {
    private UUID id;
    private String title;
    private String description;
    private ComplianceTransactionSearchCriteria criteria;
    private Integer resultCount;
    private String createdByWorkerCode;
    private LocalDateTime createdAt;
}

package hu.puzzleir.valuta.dto.compliance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/** FS-11 S2a: sablon-válasz — a criteria deserializálva, hogy a kliens visszatölthesse a szűrőket. */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComplianceSearchTemplateDto {
    private UUID id;
    private String name;
    private ComplianceTransactionSearchCriteria criteria;
    private String createdByWorkerCode;
    private LocalDateTime createdAt;
}

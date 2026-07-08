package hu.puzzleir.valuta.dto.compliance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateComplianceSearchAuditDto {
    private String title;
    private String description;
    private ComplianceTransactionSearchCriteria criteria;
}

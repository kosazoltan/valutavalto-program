package hu.puzzleir.valuta.dto.compliance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateComplianceSearchTemplateDto {
    private String name;
    private ComplianceTransactionSearchCriteria criteria;
}

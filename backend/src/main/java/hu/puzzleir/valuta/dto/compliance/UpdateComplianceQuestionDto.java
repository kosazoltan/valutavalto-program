package hu.puzzleir.valuta.dto.compliance;

import hu.puzzleir.valuta.entity.ComplianceQuestionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateComplianceQuestionDto {
    private String questionText;
    private ComplianceQuestionType questionType;
    private Integer displayOrder;
}

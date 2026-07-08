package hu.puzzleir.valuta.dto.compliance;

import hu.puzzleir.valuta.entity.ComplianceQuestionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class CreateComplianceQuestionDto {
    @NotBlank(message = "A kérdés szövege kötelező")
    private String questionText;

    @NotNull(message = "A kérdés típusa kötelező")
    private ComplianceQuestionType questionType;

    private Integer displayOrder;
}

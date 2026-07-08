package hu.puzzleir.valuta.dto.compliance;

import hu.puzzleir.valuta.entity.ComplianceQuestionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ComplianceQuestionDto {
    private UUID id;
    private String questionText;
    private ComplianceQuestionType questionType;
    private Integer displayOrder;
    private Boolean active;
    private String createdByWorkerCode;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

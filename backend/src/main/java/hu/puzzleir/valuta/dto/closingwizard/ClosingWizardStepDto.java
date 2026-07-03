package hu.puzzleir.valuta.dto.closingwizard;

import com.fasterxml.jackson.annotation.JsonRawValue;
import tools.jackson.databind.JsonNode;
import lombok.*;

import java.util.Map;

/**
 * Zárási varázsló lépés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClosingWizardStepDto {

    private Integer stepNumber;
    private String stepTitle;
    private String stepDescription;
    private Boolean completed;
    private Boolean canProceed;
    private Map<String, Object> stepData;
}

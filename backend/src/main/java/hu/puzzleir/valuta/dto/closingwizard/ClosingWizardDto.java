package hu.puzzleir.valuta.dto.closingwizard;

import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Zárási varázsló DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClosingWizardDto {

    private String id;
    private String branchId;
    private String branchName;
    private String cashDeskId;
    private String cashDeskCode;
    private String closingDate;
    private String closingType;
    private Integer currentStep;
    private Integer totalSteps;
    private String wizardStatus;
    private String startedByWorkerId;
    private String startedByWorkerName;
    private LocalDateTime startedAt;
    private String completedByWorkerId;
    private String completedByWorkerName;
    private LocalDateTime completedAt;
    private String notes;
    private List<ClosingWizardStepDto> steps;
}

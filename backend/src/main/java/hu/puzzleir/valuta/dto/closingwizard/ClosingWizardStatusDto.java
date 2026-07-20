package hu.puzzleir.valuta.dto.closingwizard;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClosingWizardStatusDto {
    private String branchId;
    private String closingDate;
    private boolean vaultContext;
    private boolean denominationRecorded;
    private boolean exactMatch;
    private String message;
    private List<Map<String, Object>> differences;
}

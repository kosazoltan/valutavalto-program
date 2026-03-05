package hu.puzzleir.valuta.dto.license;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LicenseStatusResponse {
    private String status;
    private Integer remainingDays;
    private Integer maxBranches;
    private Integer maxWorkers;
    private String features;
}

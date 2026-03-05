package hu.puzzleir.valuta.dto.license;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
public class LicenseResponse {
    private UUID id;
    private Integer companyId;
    private String licenseKey;
    private LocalDate validFrom;
    private LocalDate validTo;
    private Integer maxBranches;
    private Integer maxWorkers;
    private String features;
    private Boolean isActive;
    private String status;
    private Integer remainingDays;
}

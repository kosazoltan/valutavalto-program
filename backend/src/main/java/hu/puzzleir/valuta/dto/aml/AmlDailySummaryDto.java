package hu.puzzleir.valuta.dto.aml;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlDailySummaryDto {
    private LocalDate date;
    private int totalReports;
    private int pendingReports;
    private int submittedReports;
    private int flaggedReports;
    private long standardChecks;
    private long enhancedChecks;
    private long suspiciousChecks;
    private long thresholdChecks;
    private BigDecimal totalAmountHuf;
}

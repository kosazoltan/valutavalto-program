package hu.puzzleir.valuta.dto.aml;

import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerRiskProfileDto {
    private String customerId;
    private String customerName;
    private String riskLevel;
    private BigDecimal last30DaysTotal;
    private int last30DaysTransactionCount;
    private BigDecimal dailyTotal;
    private int dailyTransactionCount;
    private BigDecimal annualTotal;
    private boolean structuringDetected;
    private boolean highFrequency;
    private boolean highVolume;
}

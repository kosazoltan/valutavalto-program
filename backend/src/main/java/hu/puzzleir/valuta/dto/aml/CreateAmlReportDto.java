package hu.puzzleir.valuta.dto.aml;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateAmlReportDto {
    private String customerId;
    private Long transactionId;
    @NotBlank
    private String reportType;
    private String riskLevel;
    @NotNull
    private BigDecimal amountHuf;
    private String currencyCode;
    private BigDecimal originalAmount;
    private String customerName;
    private String documentType;
    private String documentNumber;
    private String workerNotes;
}

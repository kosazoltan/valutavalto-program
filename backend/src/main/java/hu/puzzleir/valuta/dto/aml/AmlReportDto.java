package hu.puzzleir.valuta.dto.aml;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlReportDto {
    private UUID id;
    private String customerId;
    private Long transactionId;
    private String reportType;
    private String riskLevel;
    private BigDecimal amountHuf;
    private String currencyCode;
    private BigDecimal originalAmount;
    private String customerName;
    private String documentType;
    private String documentNumber;
    private String workerNotes;
    private String reviewedBy;
    private LocalDateTime reviewedAt;
    private String status;
    private LocalDateTime submittedAt;
    private LocalDateTime acknowledgedAt;
    private String externalReference;
    private String createdBy;
    private LocalDateTime createdAt;
}

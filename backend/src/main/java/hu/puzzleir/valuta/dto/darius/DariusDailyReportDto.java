package hu.puzzleir.valuta.dto.darius;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DariusDailyReportDto {
    private UUID id;
    private UUID companyId;
    private LocalDate reportDate;
    private String status;

    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private Integer transactionCount;
    private BigDecimal totalHandlingFeeHuf;
    private Integer branchCount;

    private String payloadFormat;
    private String payloadHash;

    private LocalDateTime submittedAt;
    private String submittedBy;
    private String ackReference;
    private LocalDateTime ackAt;

    private String errorMessage;
    private Integer retryCount;
    private Integer maxRetries;
    private LocalDateTime nextRetryAt;

    private String approvedBy;
    private LocalDateTime approvedAt;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private String notes;

    private List<DariusReportLineDto> lines;
}

package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * MNB riport válasz DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbReportDto {

    private UUID id;
    private String reportType;
    private LocalDate reportDate;
    private String status;
    private UUID branchId;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private Integer totalTransactions;
    private LocalDateTime submittedAt;
    private LocalDateTime acceptedAt;
    private String rejectionReason;
    private List<MnbReportLineDto> lines;
    private LocalDateTime createdAt;
}

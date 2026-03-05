package hu.puzzleir.valuta.dto.decade;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DecadeReportDto {
    private UUID id;
    private UUID branchId;
    private Integer year;
    private Integer decade;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalHandlingFee;
    private Integer transactionCount;
    private String status;
    private LocalDateTime closedAt;
    private Long closedBy;
    private LocalDateTime createdAt;
}

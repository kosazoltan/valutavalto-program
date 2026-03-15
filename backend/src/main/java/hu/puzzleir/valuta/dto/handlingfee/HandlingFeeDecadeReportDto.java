package hu.puzzleir.valuta.dto.handlingfee;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Kezelési díj dekád összesítő DTO.
 * Legacy: KEZDEKAD dekád jelentés.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class HandlingFeeDecadeReportDto {
    private UUID id;
    private UUID branchId;
    private Integer year;
    private Integer decade;
    private LocalDate periodStart;
    private LocalDate periodEnd;

    private BigDecimal openingBalance;
    private BigDecimal totalBuyFee;
    private BigDecimal totalSellFee;
    private BigDecimal totalCardFee;
    private BigDecimal totalCashFee;
    private BigDecimal closingBalance;

    private Integer firstSequenceNumber;
    private Integer lastSequenceNumber;
    private Integer buyCount;
    private Integer sellCount;
    private Integer totalCount;

    private String status;
    private Boolean printed;
    private LocalDateTime closedAt;
}

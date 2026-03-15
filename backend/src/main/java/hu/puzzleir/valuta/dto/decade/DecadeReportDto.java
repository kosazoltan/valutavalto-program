package hu.puzzleir.valuta.dto.decade;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
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
    // MNB árfolyamos dekád haszon
    private BigDecimal openingInventoryValueHuf;
    private BigDecimal closingInventoryValueHuf;
    private BigDecimal decadeProfitHuf;
    private List<DecadeReportLineDto> lines;
    // Forint kontroll (Legacy: DEKRUTIN)
    private BigDecimal forintOpening;
    private BigDecimal forintTotalIncome;
    private BigDecimal forintTotalExpense;
    private BigDecimal forintClosing;
    private Boolean forintControlValid;
    private BigDecimal forintControlDiff;
    private String firstReceiptNumber;
    private String lastReceiptNumber;
    private BigDecimal cardPaymentTotal;
    private Boolean printControlFlag;
    private String status;
    private LocalDateTime closedAt;
    private Long closedBy;
    private LocalDateTime createdAt;
}

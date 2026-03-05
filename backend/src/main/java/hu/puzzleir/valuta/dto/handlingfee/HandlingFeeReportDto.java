package hu.puzzleir.valuta.dto.handlingfee;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class HandlingFeeReportDto {
    private String dateFrom;
    private String dateTo;
    private BigDecimal totalGrossFee;
    private BigDecimal totalDiscount;
    private BigDecimal totalNetFee;
    private BigDecimal totalCommissionShare;
    private Integer transactionCount;
    private List<HandlingFeeTransactionDto> items;
}

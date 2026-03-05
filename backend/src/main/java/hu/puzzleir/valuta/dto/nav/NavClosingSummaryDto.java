package hu.puzzleir.valuta.dto.nav;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * NAV zárás összesítő DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavClosingSummaryDto {

    private LocalDate closingDate;
    private BigDecimal totalRevenue;
    private BigDecimal totalExpense;
    private BigDecimal netResult;
    private BigDecimal handlingFeeTotal;
    private BigDecimal vatAmount;
    private Integer totalTransactions;
    private List<NavClosingLineDto> currencyBreakdown;
}

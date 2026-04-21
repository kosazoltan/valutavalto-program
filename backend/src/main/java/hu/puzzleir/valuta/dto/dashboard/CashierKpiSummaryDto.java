package hu.puzzleir.valuta.dto.dashboard;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * B2: Osszesitett penztaros KPI valasz — fej + rows.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashierKpiSummaryDto {
    private LocalDate dateFrom;
    private LocalDate dateTo;
    /** Osszes aktiv tranzakcio ceg szinten. */
    private long totalTxCount;
    private long totalBuyCount;
    private long totalSellCount;
    private long totalReversalCount;
    private BigDecimal totalHuf;
    private BigDecimal totalFees;
    /** Aktiv penztarosok szama az idoszakban. */
    private long activeWorkerCount;
    /** Ossz. ugyfel. */
    private long totalCustomerCount;
    /** Sztorno arany % ceg szinten. */
    private BigDecimal reversalRatio;
    /** Penztarosok KPI sorai. */
    private List<CashierKpiRowDto> rows;
}

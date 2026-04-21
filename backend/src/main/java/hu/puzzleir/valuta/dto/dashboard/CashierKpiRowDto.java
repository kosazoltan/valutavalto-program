package hu.puzzleir.valuta.dto.dashboard;

import lombok.*;

import java.math.BigDecimal;

/**
 * B2: Egy penztaros KPI sora.
 * Az ugyfelforgalom aggregacio adott idoszakra.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashierKpiRowDto {
    private Long workerId;
    private String workerName;
    private long txCount;
    private long buyCount;
    private long sellCount;
    private long reversalCount;
    private BigDecimal totalHuf;
    private BigDecimal buyHuf;
    private BigDecimal sellHuf;
    private BigDecimal totalFees;
    private long customerCount;
    /** Atlag tranzakcio HUF-ban (totalHuf / (buyCount + sellCount)). */
    private BigDecimal avgTxHuf;
    /** Sztorno arany % (reversalCount / txCount * 100). */
    private BigDecimal reversalRatio;
}

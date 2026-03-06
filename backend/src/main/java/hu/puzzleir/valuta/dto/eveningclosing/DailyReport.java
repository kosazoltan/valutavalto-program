package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Map;

/**
 * Napi jelentés — forgalom összesítő + valutanem bontás.
 *
 * Legacy: Delphi JelentesBekuldese ekvivalens.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class DailyReport {
    private Long branchId;
    private LocalDate date;
    private int totalTransactionCount;
    private int buyCount;
    private int sellCount;
    private int reversalCount;
    private int conversionCount;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalHandlingFees;
    private BigDecimal netTurnover;

    /** Valutanem bontás: currency code → forgalom összeg (HUF) */
    private Map<String, BigDecimal> currencyBreakdown;
}

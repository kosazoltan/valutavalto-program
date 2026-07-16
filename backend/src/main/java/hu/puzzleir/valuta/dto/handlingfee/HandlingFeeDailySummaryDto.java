package hu.puzzleir.valuta.dto.handlingfee;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** FK-053: napi készpénzes kezelési díj összesítő (vétel/eladás bontás). */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HandlingFeeDailySummaryDto {
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal totalBuyFee;
    private BigDecimal totalSellFee;
    private List<DailyRow> rows;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DailyRow {
        private LocalDate date;
        private BigDecimal buyFee;
        private BigDecimal sellFee;
    }
}

package hu.puzzleir.valuta.dto.turnover;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TurnoverReportDto {
    private String period;
    private BigDecimal totalBuy;
    private BigDecimal totalSell;
    private BigDecimal spread;
    private BigDecimal fees;
    private BigDecimal netProfit;
    private List<CurrencyTurnoverDto> byCurrency;
    private List<WorkerTurnoverDto> byWorker;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class CurrencyTurnoverDto {
        private String currencyCode;
        private BigDecimal buyVolume;
        private BigDecimal sellVolume;
        private BigDecimal buyHuf;
        private BigDecimal sellHuf;
        private BigDecimal fee;
        private Integer transactionCount;
        // FK-045 FR-7: MNB elszámolási árfolyam (official_rate, 100/Ft), az időszak utolsó napi
        // értéke devizánként. null, ha az adott valutához nincs MNB-árfolyam (a UI „–"-t mutat).
        private BigDecimal officialRate;
    }

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class WorkerTurnoverDto {
        private Long workerId;
        private String workerName;
        private BigDecimal totalVolume;
        private BigDecimal fee;
        private Integer transactionCount;
    }
}

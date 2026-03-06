package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * MNB napi riport DTO (company szintű, nem branch szintű).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbDailyReportDto {
    private LocalDate date;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private int totalTransactions;
    private List<MnbCurrencyLineDto> currencyLines;
}

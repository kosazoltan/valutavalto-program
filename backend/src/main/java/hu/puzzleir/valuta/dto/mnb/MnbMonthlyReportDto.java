package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

import java.math.BigDecimal;
import java.time.YearMonth;
import java.util.List;

/**
 * MNB havi riport DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbMonthlyReportDto {
    private String month;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private int totalTransactions;
    private int workingDays;
    private List<MnbCurrencyLineDto> currencyLines;
}

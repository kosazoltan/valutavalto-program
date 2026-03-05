package hu.puzzleir.valuta.dto.wu;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuDailyReportDto {
    private LocalDate date;
    private int sendCount;
    private int receiveCount;
    private BigDecimal totalSendUsd;
    private BigDecimal totalSendHuf;
    private BigDecimal totalReceiveUsd;
    private BigDecimal totalReceiveHuf;
    private BigDecimal totalFees;
}

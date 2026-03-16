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

    // SEND / RECEIVE
    private int sendCount;
    private int receiveCount;
    private BigDecimal totalSendUsd;
    private BigDecimal totalSendHuf;
    private BigDecimal totalReceiveUsd;
    private BigDecimal totalReceiveHuf;
    private BigDecimal totalFees;

    // IC (irodák közötti átadás)
    private int icInCount;
    private int icOutCount;
    private BigDecimal totalIcInUsd;
    private BigDecimal totalIcOutUsd;

    // Ügyfél be/ki (CUSTOMER_IN / CUSTOMER_OUT)
    private int customerInCount;
    private int customerOutCount;

    // Sztornók
    private int stornoCount;
    private BigDecimal totalStornoUsd;
}

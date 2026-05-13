package hu.puzzleir.valuta.dto.central;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CentralReceivedDataRowDto {
    private UUID branchId;
    private String branchCode;
    private String branchName;
    private String branchCity;
    private LocalDate reportDate;
    private String dataStatus;
    private Long dailyReportId;
    private Boolean reportReceived;
    private Boolean reportSubmitted;
    private LocalDateTime reportCreatedAt;
    private LocalDateTime submittedAt;
    private String submittedByName;
    private Integer transactionCount;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private Boolean dailyClosingDone;
    private Boolean eveningClosingDone;
    private Boolean navClosingDone;
    private String closingAlertLevel;
    private Boolean closingControlMissing;
    private String notes;
}

package hu.puzzleir.valuta.dto.dailysession;

import hu.puzzleir.valuta.entity.DailySessionStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Napi session DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailySessionDto {
    private Long id;
    private LocalDate sessionDate;
    private DailySessionStatus status;

    // Iroda
    private String branchId;
    private String branchName;

    // Nyitás
    private LocalDateTime openedAt;
    private Long openedByWorkerId;
    private String openedByWorkerName;
    private BigDecimal openingBalanceHuf;

    // Zárás
    private LocalDateTime closedAt;
    private Long closedByWorkerId;
    private String closedByWorkerName;
    private BigDecimal closingBalanceHuf;
    private Boolean denominationVerified;

    // Statisztika
    private Integer transactionCount;
    private Integer reversalCount;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalHandlingFees;

    // Számított
    private BigDecimal dailyChange;
    private BigDecimal netTurnover;
}

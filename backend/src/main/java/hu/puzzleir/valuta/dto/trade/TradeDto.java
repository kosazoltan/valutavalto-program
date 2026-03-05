package hu.puzzleir.valuta.dto.trade;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class TradeDto {
    private UUID id;
    private UUID fromBranchId;
    private String fromBranchName;
    private UUID toBranchId;
    private String toBranchName;
    private String currencyCode;
    private BigDecimal amount;
    private BigDecimal rate;
    private String status;
    private Long proposedBy;
    private Long acceptedBy;
    private LocalDateTime proposedAt;
    private LocalDateTime acceptedAt;
    private LocalDateTime completedAt;
    private String notes;
}

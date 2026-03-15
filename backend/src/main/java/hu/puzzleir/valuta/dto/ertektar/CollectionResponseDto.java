package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class CollectionResponseDto {
    private Long id;
    private String sourceBranchCode;
    private String sourceBranchName;
    private String currencyCode;
    private BigDecimal amount;
    private String status; // REQUESTED, IN_PROGRESS, COMPLETED, REJECTED
    private LocalDateTime requestedAt;
    private LocalDateTime completedAt;
    private String note;
}

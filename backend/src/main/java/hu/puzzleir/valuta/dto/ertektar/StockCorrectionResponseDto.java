package hu.puzzleir.valuta.dto.ertektar;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockCorrectionResponseDto {
    private Long id;
    private String entityType;
    private String entityId;
    private String currencyCode;
    private BigDecimal oldQuantity;
    private BigDecimal newQuantity;
    private BigDecimal difference;
    private String reason;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime approvedAt;
}

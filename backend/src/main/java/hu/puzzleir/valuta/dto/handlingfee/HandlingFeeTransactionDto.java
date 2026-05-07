package hu.puzzleir.valuta.dto.handlingfee;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class HandlingFeeTransactionDto {
    private UUID id;
    private Long transactionId;
    private String paymentMethod;
    private String feeType;
    private BigDecimal amount;
    private Integer discountPercent;
    private String discountReason;
    private BigDecimal netFee;
    private BigDecimal workerCommissionShare;
    private LocalDateTime createdAt;
}

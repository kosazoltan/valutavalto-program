package hu.puzzleir.valuta.dto.wu;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuTransactionDto {
    private UUID id;
    @NotNull
    private UUID branchId;
    private UUID wuCustomerId;
    private String transactionType;
    private String mtcn;
    private BigDecimal amountUsd;
    private BigDecimal amountHuf;
    private BigDecimal exchangeRate;
    private BigDecimal feeAmount;
    private String senderName;
    private String receiverName;
    private String destinationCountry;
    private String receiptNumber;
    private String status;
    private Long workerId;
    private LocalDateTime transactionDate;
    private LocalDateTime createdAt;
}

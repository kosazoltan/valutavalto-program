package com.puzzleir.backend.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HrkTransactionDto {
    private UUID id;
    private UUID branchId;
    private String type;
    private String currencyCode;
    private BigDecimal amount;
    private BigDecimal hufAmount;
    private String bankAccountNumber;
    private String reference;
    private String note;
    private String status;
    private Long workerId;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
}

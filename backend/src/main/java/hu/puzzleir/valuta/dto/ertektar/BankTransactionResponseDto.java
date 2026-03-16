package hu.puzzleir.valuta.dto.ertektar;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BankTransactionResponseDto {
    private Long id;
    private String transactionType;
    private String currencyCode;
    private BigDecimal amount;
    private BigDecimal exchangeRate;
    private BigDecimal hufAmount;
    private String bankName;
    private String bankReference;
    private String status;
    private String note;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
    private Integer vaultTerritoryId;
    private String vaultTerritoryName;
}

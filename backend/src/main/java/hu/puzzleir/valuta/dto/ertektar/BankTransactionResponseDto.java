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
    /** B3 workflow extension: mikor erkezett be a deviza / adtak at a banknak */
    private LocalDateTime receivedAt;
    private Long receivedBy;
    /** B3 workflow extension: mikor utalta at a HUF-ot */
    private LocalDateTime paidAt;
    private Long paidBy;
}

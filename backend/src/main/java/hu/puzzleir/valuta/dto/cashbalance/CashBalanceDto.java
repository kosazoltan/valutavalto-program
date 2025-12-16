package hu.puzzleir.valuta.dto.cashbalance;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Kassza egyenleg DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CashBalanceDto {
    private Long id;

    // Iroda
    private String branchId;
    private String branchName;

    // Valuta
    private Long currencyId;
    private String currencyCode;
    private String currencyName;
    private String currencySymbol;

    // Egyenleg
    private BigDecimal currentBalance;
    private BigDecimal openingBalance;
    private BigDecimal dailyChange;

    // Limitek
    private BigDecimal minBalance;
    private BigDecimal maxBalance;
    private boolean lowBalanceAlert;
    private boolean highBalanceAlert;

    private LocalDateTime lastTransactionAt;
    private LocalDateTime updatedAt;
}

package hu.puzzleir.valuta.dto.receipt;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptSearchResultDto {
    private Long id;
    private String receiptNumber;
    private LocalDate transactionDate;
    private LocalTime transactionTime;
    private String transactionType;
    private String transactionTypeDisplay;
    private String currencyCode;
    private BigDecimal currencyAmount;
    private BigDecimal hufAmount;
    private BigDecimal exchangeRate;
    private String customerName;
    private String cashierName;
    private String status;
}

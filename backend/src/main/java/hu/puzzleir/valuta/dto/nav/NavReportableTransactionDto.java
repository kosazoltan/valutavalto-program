package hu.puzzleir.valuta.dto.nav;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * NAV-nak jelentendő tranzakció DTO (2M+ Ft).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavReportableTransactionDto {
    private Long transactionId;
    private String receiptNumber;
    private String transactionType;
    private LocalDate transactionDate;
    private LocalTime transactionTime;
    private String currencyCode;
    private BigDecimal currencyAmount;
    private BigDecimal exchangeRate;
    private BigDecimal hufAmount;
    private String customerId;
    private String customerName;
    private String customerAddress;
    private String customerDocumentNumber;
}

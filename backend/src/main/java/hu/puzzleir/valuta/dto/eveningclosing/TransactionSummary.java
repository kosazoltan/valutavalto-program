package hu.puzzleir.valuta.dto.eveningclosing;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;

/**
 * Tranzakció összesítő a napi adatcsomagban.
 *
 * Legacy: BLOKKFEJ + BLOKKTETEL ekvivalens.
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TransactionSummary {
    private Long transactionId;
    private String receiptNumber;
    private String transactionType;
    private String status;
    private LocalDate transactionDate;
    private LocalTime transactionTime;
    private String currencyCode;
    private BigDecimal currencyAmount;
    private BigDecimal exchangeRate;
    private BigDecimal hufAmount;
    private BigDecimal handlingFee;
    private BigDecimal discountAmount;
    private BigDecimal roundingAmount;
    private String paymentMethod;
    private String customerName;
    private String customerDocumentNumber;
    private String workerName;
}

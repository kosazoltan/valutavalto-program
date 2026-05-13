package hu.puzzleir.valuta.dto.transaction;

import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * Tranzakció DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionDto {
    private Long id;
    private String receiptNumber;
    private TransactionType transactionType;
    private TransactionStatus status;
    private LocalDate transactionDate;
    private LocalTime transactionTime;

    // Valuta adatok
    private Long currencyId;
    private String currencyCode;
    private String currencyName;
    private BigDecimal currencyAmount;
    private BigDecimal exchangeRate;
    private BigDecimal hufAmount;

    // Díjak
    private BigDecimal handlingFee;
    private BigDecimal discountAmount;
    private BigDecimal discountPercent;

    // Ügyfél
    private String customerId;
    private String customerName;
    private String customerAddress;
    private String customerDocumentNumber;
    private String customerNationality;

    // Pénztáros
    private Long workerId;
    private String workerCode;
    private String workerName;

    // Iroda
    private String branchId;
    private String branchName;

    // Sztornó
    private Long originalTransactionId;
    private String originalReceiptNumber;
    private String reversalReason;
    private String approvedBy;

    // Devizastatusz
    private String foreignStatus;

    // Egyéb
    private String notes;
    private Boolean printed;
    private String mtcn;
    private String referenceNumber;
    private LocalDateTime createdAt;

    // Multi-line bizonylat
    private Boolean multiLine;
    private Integer lineCount;
    private List<TransactionLineDto> lines;
}

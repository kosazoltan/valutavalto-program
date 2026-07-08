package hu.puzzleir.valuta.dto.compliance;

import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * FS-11 S1: cégszintű compliance tranzakció-találati sor DTO.
 * Csak meglévő Transaction snapshot mezőket tartalmaz; pénzértéket nem kerekít újra.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComplianceTransactionRowDto {
    private Long id;
    private String receiptNumber;
    private TransactionType transactionType;
    private TransactionStatus status;
    private LocalDate transactionDate;
    private LocalTime transactionTime;
    private UUID branchId;
    private String branchName;
    private String branchCode;
    private Long currencyId;
    private String currencyCode;
    private BigDecimal currencyAmount;
    private BigDecimal exchangeRate;
    private BigDecimal hufAmount;
    private PaymentMethod paymentMethod;
    private Boolean cashierCustomRate;
    private Boolean kkDiscount;
    private Boolean customerIsPep;
    private Boolean customerOnOwnBehalf;
    private Boolean amlSuspicious;
    private String customerId;
    private String customerName;
    private LocalDate customerBirthDate;
    private String customerNationality;
    private String customerDocumentNumber;
    private Boolean isLegalEntityCustomer;
    private String legalEntityName;
    private String legalEntityTaxNumber;
    private String workerCode;
    private String workerName;
    private String originalReceiptNumber;
}

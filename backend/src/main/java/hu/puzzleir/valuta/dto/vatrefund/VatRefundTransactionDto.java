package hu.puzzleir.valuta.dto.vatrefund;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * ÁFA visszatérítés tranzakció DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VatRefundTransactionDto {
    private Long id;
    private UUID companyId;
    private String voucherType;
    private String serialNumber;
    private LocalDate transactionDate;
    private LocalTime transactionTime;
    private Integer mainUnit;
    private BigDecimal supplyAmount;
    private BigDecimal grossAmount;
    private BigDecimal vatAmount;
    private BigDecimal vatPercentage;
    private String customerName;
    private String customerAddress;
    private String customerIdentifier;
    private String bankAccountNumber;
    private String companyName;
    private String siteAddress;
    private String deedNumber;
    private Boolean isReversed;
    private Long originalTransactionId;
    private String createdByWorker;
    private LocalDateTime createdAt;
}

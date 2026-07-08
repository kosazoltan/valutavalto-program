package hu.puzzleir.valuta.dto.compliance;

import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionType;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FS-11 S1: cégszintű compliance tranzakció-kereső opcionális szűrői.
 * A companyId szándékosan nincs a DTO-ban: azt a service kizárólag a SecurityContextből olvassa.
 */
@Data
@NoArgsConstructor
public class ComplianceTransactionSearchCriteria {
    private UUID branchId;
    private LocalDate startDate;
    private LocalDate endDate;
    private TransactionType type;
    private BigDecimal minHufAmount;
    private BigDecimal maxHufAmount;
    private List<Long> currencyIds;
    private PaymentMethod paymentMethod;
    private boolean customRateOnly;
    private boolean kkDiscountOnly;
    private boolean onBehalfOfOtherOnly;
    private boolean pepOnly;
    private String customerName;
    private LocalDate customerBirthDate;
    private String customerNationality;
    private String customerDocumentNumber;
    private boolean legalEntityOnly;
    private String legalEntityName;
    private String legalEntityTaxNumber;
    private String legalDeedNumber;
    private String legalEntitySeat;
}

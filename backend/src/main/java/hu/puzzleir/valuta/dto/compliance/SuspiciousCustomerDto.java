package hu.puzzleir.valuta.dto.compliance;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

/** FS-12: gyanús ügyfél aggregátum-sor a 3 minta flagjeivel. */
@Getter
@Builder
public class SuspiciousCustomerDto {
    private final String customerId;
    private final String customerName;
    private final long transactionCount;
    private final BigDecimal totalHufAmount;
    private final long branchCount;
    private final boolean highTransactionCount;
    private final boolean highTotalValue;
    private final boolean manyBranches;
}

package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;

import java.math.BigDecimal;

/**
 * FK-096: iroda-szintű kezelési díj konfiguráció — admin lista + modal DTO.
 * A {@code version} a DRAFT sor @Version értéke (0 legitim első publikálás, B2);
 * DRAFT hiányában a LIVE sor verziója kerül ide.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeeConfigDto {
    private java.util.UUID branchId;
    private String feeMode;
    private BigDecimal perMilleRate;
    private BigDecimal perMilleCap;
    private boolean hasDraft;
    private String status;
    private Long version;
}

package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * FK-096: admin lista-sor — egy iroda LIVE + DRAFT díjkonfigurációjának összefoglalója.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeeConfigRowDto {
    private UUID branchId;
    private String branchCode;
    private String branchName;
    private String region;
    private String liveFeeMode;
    private BigDecimal livePerMilleRate;
    private BigDecimal livePerMilleCap;
    private boolean hasDraft;
    private String draftFeeMode;
    private BigDecimal draftPerMilleRate;
    private BigDecimal draftPerMilleCap;
    /**
     * A DRAFT sor @Version értéke (publish expectedVersion, B2: 0 legitim);
     * DRAFT hiányában a LIVE sor verziója.
     */
    private Long version;
}

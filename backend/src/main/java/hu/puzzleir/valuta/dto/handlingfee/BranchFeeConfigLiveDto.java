package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FK-096/FR-14 + FK-097: az iroda SAJÁT éles díjkonfigurációja
 * (pénztáros read-only kártya + szinkron-végpont). DRAFT sosem szerepel itt.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeeConfigLiveDto {
    private UUID branchId;
    private String branchCode;
    private String feeMode;
    private BigDecimal perMilleRate;
    private BigDecimal perMilleCap;
    private LocalDate validFrom;
    private List<HandlingFeeBracketDto> brackets;
}

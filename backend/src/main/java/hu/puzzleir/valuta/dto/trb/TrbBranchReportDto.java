package hu.puzzleir.valuta.dto.trb;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Egy iroda TRB jelentése — pénztárállomány + ügyfélforgalom.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrbBranchReportDto {
    private String branchCode;
    private String branchName;
    /** Pénztárállomány: valutanemenként, címletenként */
    private List<TrbDenominationLineDto> denominationLines;
    /** Ügyfélforgalom: valutanemenként eladott/vett */
    private List<TrbCurrencyLineDto> customerTurnoverLines;
}

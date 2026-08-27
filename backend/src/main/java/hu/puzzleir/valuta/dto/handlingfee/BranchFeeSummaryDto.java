package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;

/**
 * FK-096: admin nézet összefoglaló kártyái (D7: counterparty-irodák nélkül).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeeSummaryDto {
    private long totalBranches;
    private long configuredBranches;
    private long bracketBranches;
    private long perMilleBranches;
}

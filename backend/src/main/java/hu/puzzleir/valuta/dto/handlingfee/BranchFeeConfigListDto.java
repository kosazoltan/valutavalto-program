package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;

import java.util.List;

/**
 * FK-096/D11: az admin lista végpont válasz-alakja — { summary, rows }.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchFeeConfigListDto {
    private BranchFeeSummaryDto summary;
    private List<BranchFeeConfigRowDto> rows;
}

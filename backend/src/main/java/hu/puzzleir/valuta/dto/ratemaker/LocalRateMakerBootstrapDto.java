package hu.puzzleir.valuta.dto.ratemaker;

import hu.puzzleir.valuta.dto.ratecreation.RateOverviewDTO;
import hu.puzzleir.valuta.dto.ratecreation.WorkgroupDetailDTO;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocalRateMakerBootstrapDto {
    private LocalDateTime generatedAt;
    private String mode;
    private String publishEndpoint;
    private boolean idempotencyRequired;
    private RateOverviewDTO overview;
    private List<WorkgroupDetailDTO> workgroups;
}

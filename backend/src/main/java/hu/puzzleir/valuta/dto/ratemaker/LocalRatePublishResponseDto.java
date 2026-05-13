package hu.puzzleir.valuta.dto.ratemaker;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LocalRatePublishResponseDto {
    private UUID publicationId;
    private UUID workgroupId;
    private LocalDateTime publishedAt;
    private int acceptedRates;
    private int affectedBranches;
    private String status;
    private String serverPackageHash;
    private List<String> branchCodes;
}

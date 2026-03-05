package hu.puzzleir.valuta.dto.competition;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class CompetitionEntryDto {
    private UUID id;
    private UUID competitionId;
    private Long workerId;
    private String workerName;
    private BigDecimal totalVolume;
    private Integer transactionCount;
    private BigDecimal score;
    private Integer rank;
}

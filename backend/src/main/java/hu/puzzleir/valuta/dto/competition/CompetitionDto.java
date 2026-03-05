package hu.puzzleir.valuta.dto.competition;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class CompetitionDto {
    private UUID id;
    private String competitionName;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;
    private String rules;
    private LocalDateTime createdAt;
}

package hu.puzzleir.valuta.dto.competition;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data @NoArgsConstructor @AllArgsConstructor
public class CreateCompetitionDto {

    @NotBlank
    private String competitionName;

    @NotNull
    private LocalDate startDate;

    @NotNull
    private LocalDate endDate;

    private String rules;
}

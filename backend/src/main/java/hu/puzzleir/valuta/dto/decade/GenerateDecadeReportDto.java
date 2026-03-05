package hu.puzzleir.valuta.dto.decade;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor
public class GenerateDecadeReportDto {

    @NotNull
    private UUID branchId;

    @NotNull
    @Min(2020)
    @Max(2100)
    private Integer year;

    @NotNull
    @Min(1)
    @Max(36)
    private Integer decade;
}

package hu.puzzleir.valuta.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;
import java.util.UUID;

@Data
public class ClosingMarkDoneRequestDto {
    @NotNull
    private UUID branchId;

    @NotNull
    private LocalDate date;

    @NotNull
    private ClosingMarkType type;
}

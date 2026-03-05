package hu.puzzleir.valuta.dto.dataimport;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ImportRequestDto {
    @NotNull
    private UUID branchId;
    private LocalDate date;
    private LocalDate fromDate;
    private LocalDate toDate;
}

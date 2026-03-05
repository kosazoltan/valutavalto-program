package hu.puzzleir.valuta.dto.datacollection;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Adatgyűjtés kérés DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CollectRequestDto {

    @NotNull(message = "Iroda ID kötelező")
    private UUID branchId;

    @NotNull(message = "Dátum kötelező")
    private LocalDate date;
}

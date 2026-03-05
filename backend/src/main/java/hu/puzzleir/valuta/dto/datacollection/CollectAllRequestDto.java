package hu.puzzleir.valuta.dto.datacollection;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;

/**
 * Összes iroda adatgyűjtés kérés DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CollectAllRequestDto {

    @NotNull(message = "Dátum kötelező")
    private LocalDate date;
}

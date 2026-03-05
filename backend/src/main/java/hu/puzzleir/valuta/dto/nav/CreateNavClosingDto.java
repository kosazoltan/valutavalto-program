package hu.puzzleir.valuta.dto.nav;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

/**
 * NAV napi zárás kérés DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateNavClosingDto {

    @NotNull(message = "Iroda ID kötelező")
    private UUID branchId;

    @NotNull(message = "Dátum kötelező")
    private LocalDate date;
}

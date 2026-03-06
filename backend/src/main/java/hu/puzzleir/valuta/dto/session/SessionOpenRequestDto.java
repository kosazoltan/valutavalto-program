package hu.puzzleir.valuta.dto.session;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

/**
 * Pénztárnyitás kérés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionOpenRequestDto {

    @NotNull(message = "Pénztáros ID kötelező")
    private Long workerId;

    @NotNull(message = "Iroda ID kötelező")
    private UUID branchId;
}

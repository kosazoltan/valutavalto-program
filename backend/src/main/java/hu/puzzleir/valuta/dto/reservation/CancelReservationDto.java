package hu.puzzleir.valuta.dto.reservation;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Foglaló stornó DTO.
 *
 * Legacy: VisszaFizetoProcedura
 * - Ügyfél stornó (_visszatipus=2): reason opcionális
 * - EBC stornó (_visszatipus=3): reason kötelező + supervisor jóváhagyás
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CancelReservationDto {

    /** Stornó oka (EBC stornónál kötelező) */
    @Size(max = 500, message = "Indoklás max 500 karakter")
    private String reason;

    /** Supervisor worker ID (EBC stornónál kötelező — idő előtti kifizetéshez is) */
    private Long supervisorWorkerId;
}

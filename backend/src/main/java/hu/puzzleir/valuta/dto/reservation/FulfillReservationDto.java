package hu.puzzleir.valuta.dto.reservation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Foglaló teljesítés DTO.
 *
 * Legacy: VisszaFizetoProcedura _visszatipus=1 "ÜGYLET RENDBEN"
 * Ügyfél megkapja a valutát, fizetendő = foglaló összeg.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FulfillReservationDto {

    /** Megjegyzés (opcionális) */
    private String notes;
}

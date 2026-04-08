package hu.puzzleir.valuta.dto.trb;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Egy címlet sor a pénztárállomány jelentésben.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrbDenominationLineDto {
    private String currencyCode;
    private int denomination;
    private int quantity;
}

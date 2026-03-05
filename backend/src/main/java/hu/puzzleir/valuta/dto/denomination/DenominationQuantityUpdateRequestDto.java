package hu.puzzleir.valuta.dto.denomination;

import lombok.*;

/**
 * Címlet darabszám frissítési kérés DTO (batch frissítéshez).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DenominationQuantityUpdateRequestDto {

    private String denominationId;
    private Integer quantity;
}

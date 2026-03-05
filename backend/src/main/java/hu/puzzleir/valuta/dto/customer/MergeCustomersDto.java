package hu.puzzleir.valuta.dto.customer;

import jakarta.validation.constraints.NotNull;
import lombok.*;

/**
 * Ügyfél duplikátum összevonás kérés
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MergeCustomersDto {
    @NotNull
    private Long primaryId;
    @NotNull
    private Long duplicateId;
}

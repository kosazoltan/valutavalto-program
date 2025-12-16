package hu.puzzleir.valuta.dto.denomination;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Címlet frissítés DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateDenominationDto {

    @NotNull(message = "Valuta azonosító kötelező")
    private Long currencyId;

    @NotNull(message = "Címlet értéke kötelező")
    private BigDecimal faceValue;

    @NotNull(message = "Darabszám kötelező")
    @Min(value = 0, message = "A darabszám nem lehet negatív")
    private Integer newQuantity;
}

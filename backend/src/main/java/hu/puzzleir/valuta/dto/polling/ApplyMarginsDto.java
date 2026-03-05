package hu.puzzleir.valuta.dto.polling;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Margin alkalmazás DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplyMarginsDto {

    @NotNull(message = "currencyId kötelező")
    private Long currencyId;

    @NotNull(message = "spread kötelező")
    @Positive(message = "A spread-nek pozitívnak kell lennie")
    private BigDecimal spread;
}

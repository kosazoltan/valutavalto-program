package hu.puzzleir.valuta.dto.calculator;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Fordított kalkuláció kérés DTO (mennyi deviza adott HUF összegért).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReverseRequestDto {

    @NotBlank(message = "Valutakód kötelező")
    @Size(min = 3, max = 3, message = "Valutakód 3 karakteres")
    private String currency;

    @NotNull(message = "HUF összeg kötelező")
    @DecimalMin(value = "1", message = "A HUF összegnek pozitívnak kell lennie")
    private BigDecimal hufAmount;
}

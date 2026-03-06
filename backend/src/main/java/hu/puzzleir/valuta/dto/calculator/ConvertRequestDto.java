package hu.puzzleir.valuta.dto.calculator;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Deviza átváltási kérés DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConvertRequestDto {

    @NotBlank(message = "Forrás valuta kötelező")
    @Size(min = 3, max = 3, message = "Valutakód 3 karakteres")
    private String fromCurrency;

    @NotBlank(message = "Cél valuta kötelező")
    @Size(min = 3, max = 3, message = "Valutakód 3 karakteres")
    private String toCurrency;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek pozitívnak kell lennie")
    private BigDecimal amount;

    @NotBlank(message = "Irány kötelező (BUY/SELL)")
    @Pattern(regexp = "BUY|SELL", message = "Irány csak BUY vagy SELL lehet")
    private String direction; // BUY or SELL
}

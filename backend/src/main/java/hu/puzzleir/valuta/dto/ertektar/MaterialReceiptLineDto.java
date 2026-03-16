package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaterialReceiptLineDto {

    @NotBlank(message = "Valutakód kötelező")
    private String currencyCode;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek pozitívnak kell lennie")
    private BigDecimal amount;

    private BigDecimal exchangeRate;
    private BigDecimal hufEquivalent;
}

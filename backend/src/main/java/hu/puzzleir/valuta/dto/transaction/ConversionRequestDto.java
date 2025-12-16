package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Konverzió request DTO (valuta-valuta csere)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversionRequestDto {

    @NotNull(message = "Forrás valuta azonosító kötelező")
    private Long fromCurrencyId;

    @NotNull(message = "Cél valuta azonosító kötelező")
    private Long toCurrencyId;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal fromAmount;

    @DecimalMin(value = "0", message = "A kezelési díj nem lehet negatív")
    private BigDecimal handlingFee;

    private String customerId;
    private String customerName;
}

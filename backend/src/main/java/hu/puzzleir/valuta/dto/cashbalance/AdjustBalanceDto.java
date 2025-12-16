package hu.puzzleir.valuta.dto.cashbalance;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Kassza egyenleg módosítás DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdjustBalanceDto {

    @NotNull(message = "Valuta azonosító kötelező")
    private Long currencyId;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal amount;

    @NotNull(message = "Irány kötelező (true=bevétel, false=kiadás)")
    private Boolean incoming;

    private String reason;
}

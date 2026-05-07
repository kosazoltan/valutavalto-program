package hu.puzzleir.valuta.dto.wu;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class WuDailyLimitUseRequest {

    @NotNull
    @DecimalMin(value = "0.01")
    private BigDecimal amountUsd;

    private LocalDate businessDate;
}

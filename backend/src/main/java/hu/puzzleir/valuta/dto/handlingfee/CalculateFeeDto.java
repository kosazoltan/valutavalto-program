package hu.puzzleir.valuta.dto.handlingfee;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data @NoArgsConstructor @AllArgsConstructor
public class CalculateFeeDto {

    private Long transactionId;

    @NotNull
    @Positive
    private BigDecimal hufAmount;
}

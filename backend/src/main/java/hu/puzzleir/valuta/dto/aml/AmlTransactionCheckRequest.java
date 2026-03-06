package hu.puzzleir.valuta.dto.aml;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlTransactionCheckRequest {
    @NotNull
    private BigDecimal amountHuf;
    private String customerId;
    private String currencyCode;
}

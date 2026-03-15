package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Builder
public class CashBalanceDto {
    private String currency;
    private BigDecimal amount;
}

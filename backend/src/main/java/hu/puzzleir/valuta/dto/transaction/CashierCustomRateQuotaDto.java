package hu.puzzleir.valuta.dto.transaction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CashierCustomRateQuotaDto {
    private long used;
    private long limit;
    private long remaining;
    private long minAmountHuf;
}

package hu.puzzleir.valuta.dto.receipt;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReceiptLineDto {
    private Integer lineNumber;
    private String currencyCode;
    private BigDecimal appliedRate;
    private BigDecimal banknoteCount;
    private BigDecimal hufValue;
    private BigDecimal lineDiscount;
}

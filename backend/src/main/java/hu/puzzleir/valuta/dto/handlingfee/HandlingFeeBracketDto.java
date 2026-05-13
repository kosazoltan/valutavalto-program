package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;
import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HandlingFeeBracketDto {
    private Long id;
    private Integer bracketOrder;
    private BigDecimal upperLimit;
    private BigDecimal feeAmount;
    private Boolean active;
}

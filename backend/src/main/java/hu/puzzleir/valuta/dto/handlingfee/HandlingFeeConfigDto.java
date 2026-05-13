package hu.puzzleir.valuta.dto.handlingfee;

import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HandlingFeeConfigDto {
    private String feeType;
    private BigDecimal perMilleRate;
    private BigDecimal perMilleMaxAmount;
    private List<HandlingFeeBracketDto> brackets;
}

package hu.puzzleir.valuta.dto.calculator;

import lombok.*;

import java.math.BigDecimal;

/**
 * Fordított kalkuláció kérés DTO (mennyi deviza adott HUF összegért).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReverseRequestDto {

    private String currency;
    private BigDecimal hufAmount;
}

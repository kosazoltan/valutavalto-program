package hu.puzzleir.valuta.dto.nav;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * NAV zárás sor DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NavClosingLineDto {

    private UUID id;
    private String currencyCode;
    private BigDecimal buyAmount;
    private BigDecimal sellAmount;
    private BigDecimal buyHuf;
    private BigDecimal sellHuf;
    private BigDecimal handlingFee;
    private Integer transactionCount;
}

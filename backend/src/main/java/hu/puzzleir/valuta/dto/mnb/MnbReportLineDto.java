package hu.puzzleir.valuta.dto.mnb;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * MNB riport sor DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MnbReportLineDto {

    private UUID id;
    private String currencyCode;
    private BigDecimal buyAmount;
    private BigDecimal sellAmount;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private Integer transactionCount;
}

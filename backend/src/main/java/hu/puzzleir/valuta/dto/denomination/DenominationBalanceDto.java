package hu.puzzleir.valuta.dto.denomination;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Pénztárgép címlet egyenleg DTO.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DenominationBalanceDto {

    private String id;
    private String cashDeskId;
    private String cashDeskCode;
    private String denominationId;
    private BigDecimal denominationValue;
    private String denominationType;
    private String currencyCode;
    private Integer quantity;
    private BigDecimal totalValue;
    private LocalDateTime updatedAt;
}

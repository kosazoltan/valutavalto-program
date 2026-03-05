package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BankRateDTO {
    private Long currencyId;
    private String currencyCode;
    private BigDecimal bankBuyRate;
    private BigDecimal bankSellRate;
    private BigDecimal middleRate;
    private LocalDateTime lastUpdated;
}

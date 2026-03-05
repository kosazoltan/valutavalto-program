package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompetitorRateDTO {
    private UUID competitorId;
    private String competitorName;
    private String currencyCode;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private BigDecimal margin;
    private LocalDateTime lastUpdated;
}

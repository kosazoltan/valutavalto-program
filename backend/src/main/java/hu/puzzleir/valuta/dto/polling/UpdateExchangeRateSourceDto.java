package hu.puzzleir.valuta.dto.polling;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * ExchangeRateSource frissítés DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateExchangeRateSourceDto {
    private Integer pollIntervalMinutes;
    private Boolean active;
}

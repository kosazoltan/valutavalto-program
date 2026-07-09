package hu.puzzleir.valuta.dto.mnbsettlement;

import java.math.BigDecimal;
import java.time.Instant;

public record MnbSettlementRateDto(
        String currencyCode,
        String currencyName,
        BigDecimal officialRate,
        Instant availableToOfficesAt) {
}

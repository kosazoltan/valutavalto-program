package hu.puzzleir.valuta.dto.mnbsettlement;

import java.math.BigDecimal;

public record MnbQueryRateDto(String currencyCode, BigDecimal officialRate) {
}

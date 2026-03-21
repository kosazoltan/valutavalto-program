package hu.puzzleir.valuta.dto.wu.stub;

import lombok.Builder;

import java.math.BigDecimal;

@Builder
public record WuStubRateResponse(
        String pair,
        BigDecimal buyRate,
        BigDecimal sellRate,
        String provider
) {
}

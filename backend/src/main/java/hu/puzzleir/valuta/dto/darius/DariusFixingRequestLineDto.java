package hu.puzzleir.valuta.dto.darius;

import java.math.BigDecimal;

public record DariusFixingRequestLineDto(
        String currencyCode,
        BigDecimal deliveredAmount,
        BigDecimal collectedAmount) {}

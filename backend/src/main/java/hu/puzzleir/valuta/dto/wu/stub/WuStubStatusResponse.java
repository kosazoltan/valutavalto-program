package hu.puzzleir.valuta.dto.wu.stub;

import lombok.Builder;

import java.time.LocalDateTime;
import java.util.UUID;

@Builder
public record WuStubStatusResponse(
        String mtcn,
        String status,
        String transactionType,
        UUID transactionId,
        LocalDateTime transactionDate,
        String provider
) {
}

package hu.puzzleir.valuta.dto.polling;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * ExchangeRateSource DTO.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExchangeRateSourceDto {
    private Long id;
    private String name;
    private String url;
    private Integer pollIntervalMinutes;
    private Boolean active;
    private LocalDateTime lastSuccessAt;
    private LocalDateTime lastErrorAt;
    private String lastError;
    private Long successCount;
    private Long errorCount;
}

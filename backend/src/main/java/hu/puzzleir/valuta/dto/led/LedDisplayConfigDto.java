package hu.puzzleir.valuta.dto.led;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class LedDisplayConfigDto {
    private UUID id;
    private UUID branchId;
    private String displayType;
    private String connectionString;
    private Boolean isActive;
    private Integer refreshIntervalSeconds;
    private String displayedCurrencies;
    private LocalDateTime lastUpdatedAt;
}

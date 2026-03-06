package hu.puzzleir.valuta.dto.led;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.UUID;

/**
 * LED kijelző konfiguráció mentés request.
 */
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class SaveLedDisplayConfigRequest {

    @NotNull
    private UUID branchId;

    private String displayType;
    private String connectionString;
    private Boolean isActive;
    private Integer refreshIntervalSeconds;
    private String displayedCurrencies;
}

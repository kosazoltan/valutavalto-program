package hu.puzzleir.valuta.dto.sync;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncInboundEventRequest {

    @NotBlank
    private String sourceNodeId;

    @NotBlank
    private String eventType;

    @NotNull
    private JsonNode payload;
}

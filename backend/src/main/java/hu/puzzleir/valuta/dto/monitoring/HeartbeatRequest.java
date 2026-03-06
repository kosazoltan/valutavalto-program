package hu.puzzleir.valuta.dto.monitoring;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class HeartbeatRequest {
    @NotNull(message = "Iroda ID kötelező")
    private UUID branchId;
}

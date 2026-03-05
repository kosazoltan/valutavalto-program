package hu.puzzleir.valuta.dto.monitoring;

import lombok.Data;

import java.util.UUID;

@Data
public class HeartbeatRequest {
    private UUID branchId;
}

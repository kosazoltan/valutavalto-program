package hu.puzzleir.valuta.dto.monitoring;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class BranchStatusResponse {
    private UUID id;
    private UUID branchId;
    private LocalDateTime lastHeartbeat;
    private LocalDateTime lastSync;
    private Boolean isOnline;
    private LocalDateTime lastTransactionAt;
    private Integer dailyTransactionCount;
    private BigDecimal dailyVolumeHuf;
    private Integer openAlerts;
}

package hu.puzzleir.valuta.dto.ertektar;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
public class SubordinateBranchDto {
    private String code;
    private String name;
    private UUID companyId;
    private LocalDateTime lastSyncAt;
    private String onlineStatus; // online, warning, offline
    private List<CashBalanceDto> cashBalances;
    private long totalHufValue;
    private long dailyTurnover;
}

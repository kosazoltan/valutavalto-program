package hu.puzzleir.valuta.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchWithStatsDto {

    private String id;
    private String code;
    private String name;
    private String city;
    private String companyName;
    private boolean active;

    private int workerCount;
    private BigDecimal dailyTurnoverHuf;
    private String lastSyncAt;
    private String syncStatus;
}

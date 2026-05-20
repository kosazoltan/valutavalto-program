package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegionSnapshotDto {
    private String regionCode;
    private String regionName;
    private List<BranchSnapshotDto> branches;
    private BranchStockTotalsDto totals;
    /** A körzet legfrissebb branch-készlet frissítése (max branch.lastUpdated), VV-ELVI lastSyncedAt. */
    private LocalDateTime lastSyncedAt;
}

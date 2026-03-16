package hu.puzzleir.valuta.dto.stocksnapshot;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StockSnapshotDto {
    private LocalDateTime snapshotTime;
    private UUID companyId;
    private String companyName;
    private List<RegionSnapshotDto> regions;
    private BranchStockTotalsDto companyTotals;
}

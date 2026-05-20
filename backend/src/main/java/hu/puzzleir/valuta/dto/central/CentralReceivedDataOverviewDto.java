package hu.puzzleir.valuta.dto.central;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CentralReceivedDataOverviewDto {
    private LocalDate reportDate;
    private Integer totalBranches;
    private Integer receivedReports;
    private Integer submittedReports;
    private Integer missingReports;
    private Integer warningClosings;
    private Integer criticalClosings;
    private Integer totalTransactions;
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private BigDecimal totalFeeHuf;
    private BigDecimal totalProfit;
    private LocalDateTime generatedAt;
    /**
     * A legfrissebb átvett branch-adat időpontja (submittedAt elsőbbség, fallback reportCreatedAt).
     * null, ha egyetlen branch sem küldött még adatot az adott napra — ekkor a globális NON_NULL
     * Jackson-inclusion (JacksonConfig) miatt a mező KIMARAD a JSON-ból (a frontend opcionálisként
     * kezeli). A frontend frissesség-badge forrása (VV-ELVI 6. — "központ aggregál, nem vezérel":
     * az adat frissessége explicit látható).
     */
    private LocalDateTime lastSyncedAt;
    private List<CentralReceivedDataRowDto> rows;
}

package hu.puzzleir.valuta.dto.mnb;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Haromszintu MNB osszesito: penztar -> koerzet -> ceg.
 * Legacy: Delphi ForgalomGyujtes + KorzetSumma + KftSumma + CegSumma.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MnbHierarchicalReportDto {

    private LocalDate date;
    private String companyName;

    /** Ceg szintu osszesites (legfelso szint) */
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private int totalTransactions;
    private List<MnbCurrencyLineDto> companyCurrencyLines;

    /** Koerzet szintu bontasok */
    private List<MnbRegionReportDto> regionReports;

    /** Koerzethez nem rendelt irodak (regionCode IS NULL) */
    private MnbRegionReportDto unassignedBranches;
}

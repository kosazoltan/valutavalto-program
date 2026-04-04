package hu.puzzleir.valuta.dto.mnb;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Négyszintű MNB összesítő: pénztár → körzet → KFT → cég.
 *
 * Legacy: Delphi ForgalomGyujtes + KorzetSumma + KftSumma + CegSumma + AdatKiertekeles.
 *
 * S1-01 bővítés:
 * - Készlet adatok (nyitó/záró/mozgások) minden szinten
 * - KFT (jogi személy csoport) szint
 * - Validáció (számított záró vs. tényleges záró)
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MnbHierarchicalReportDto {

    private LocalDate date;
    private String companyName;

    /** Cég szintű összesítés (legfelső szint — Delphi: CegSumma) */
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private int totalTransactions;
    private List<MnbCurrencyLineDto> companyCurrencyLines;

    /** KFT (jogi személy csoport) szintű bontás — Delphi: KftSumma */
    private List<MnbCompanyGroupReportDto> companyGroupReports;

    /** Körzet szintű bontás — Delphi: KorzetSumma */
    private List<MnbRegionReportDto> regionReports;

    /** Körzethez nem rendelt irodák (regionCode IS NULL) */
    private MnbRegionReportDto unassignedBranches;

    /** Validáció összesítő — Delphi: AdatKiertekeles */
    private int validBranchCount;
    private int invalidBranchCount;
    private List<String> validationErrors;
}

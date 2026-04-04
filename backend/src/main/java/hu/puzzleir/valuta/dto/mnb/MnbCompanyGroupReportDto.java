package hu.puzzleir.valuta.dto.mnb;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * KFT (jogi személy csoport) szintű MNB összesítő DTO.
 *
 * Legacy: Delphi KftSumma + KftFeliras — 2 KFT: "B" (irodaszám < 151) és "Z" (>= 151).
 * A modern rendszerben Company entity alapján csoportosítjuk, ami rugalmasabb.
 *
 * Háromszintű hierarchia: pénztár → körzet → KFT → cég
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MnbCompanyGroupReportDto {

    private LocalDate date;

    /** KFT azonosító betűjel (legacy: "B" vagy "Z") */
    private String groupCode;

    /** KFT neve */
    private String groupName;

    /** KFT szintű összesítés */
    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private int totalTransactions;

    /** Bankkártya forgalom összesen (HUF) */
    @Builder.Default
    private BigDecimal totalCardPayment = BigDecimal.ZERO;

    /** Valutánkénti bontás (készlettel) */
    private List<MnbCurrencyLineDto> currencyLines;

    /** A KFT-hez tartozó körzetek */
    private List<MnbRegionReportDto> regionReports;
}

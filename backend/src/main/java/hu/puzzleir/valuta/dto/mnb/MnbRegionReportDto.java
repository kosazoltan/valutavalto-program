package hu.puzzleir.valuta.dto.mnb;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Koerzet szintu MNB riport DTO.
 * Legacy: Delphi KorzetSumma - penztarokbol aggregalt koerzeti osszesites.
 * Haromszintu hierarchia: penztar -> koerzet -> ceg.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MnbRegionReportDto {

    private LocalDate date;
    private String regionCode;
    private String regionName;
    private int branchCount;

    private BigDecimal totalBuyHuf;
    private BigDecimal totalSellHuf;
    private int totalTransactions;

    private List<MnbCurrencyLineDto> currencyLines;
    private List<BranchSummary> branchSummaries;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BranchSummary {
        private String branchCode;
        private String branchName;
        private BigDecimal buyHuf;
        private BigDecimal sellHuf;
        private int transactionCount;
    }
}

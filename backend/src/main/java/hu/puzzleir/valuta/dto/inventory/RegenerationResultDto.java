package hu.puzzleir.valuta.dto.inventory;

import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegenerationResultDto {
    private Long id;
    private String branchId;
    private List<DiscrepancyDto> discrepancies;
    private List<String> correctedCurrencies;
    private Integer discrepancyCount;
    private Integer correctedCount;
    private String regeneratedAt;
    private String regeneratedByName;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class DiscrepancyDto {
        private String currencyCode;
        private String expectedAmount;
        private String actualAmount;
        private String difference;
    }
}

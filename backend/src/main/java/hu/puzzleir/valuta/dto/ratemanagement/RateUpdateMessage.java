package hu.puzzleir.valuta.dto.ratemanagement;

import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateUpdateMessage {
    private UUID workgroupId;
    private List<String> branchCodes;
    private LocalDateTime publishedAt;
    private List<RateEntry> rates;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class RateEntry {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal buyRate;
        private BigDecimal sellRate;
        private Integer roundingRule;
    }
}

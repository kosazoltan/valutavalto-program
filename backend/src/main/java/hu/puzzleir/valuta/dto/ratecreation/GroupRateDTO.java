package hu.puzzleir.valuta.dto.ratecreation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupRateDTO {
    private UUID groupId;
    private List<RateEntry> rates;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RateEntry {
        private Long currencyId;
        private BigDecimal buyRate;
        private BigDecimal sellRate;
    }
}

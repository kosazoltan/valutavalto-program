package hu.puzzleir.valuta.dto.ratemanagement;

import lombok.*;
import java.math.BigDecimal;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateTemplateDto {
    private UUID id;
    private Long currencyId;
    private String currencyCode;
    private UUID workgroupId;
    private String workgroupName;
    private BigDecimal baseBuyRate;
    private BigDecimal baseSellRate;
    private BigDecimal buySpread;
    private BigDecimal sellSpread;
    private Integer roundingRule;
    private String status;
}

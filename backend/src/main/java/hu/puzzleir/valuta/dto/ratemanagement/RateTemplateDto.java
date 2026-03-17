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
    private BigDecimal officialRate;
    private BigDecimal limit1Amount;
    private BigDecimal limit1BuyRate;
    private BigDecimal limit1SellRate;
    private BigDecimal limit2Amount;
    private BigDecimal limit2BuyRate;
    private BigDecimal limit2SellRate;
    private BigDecimal limit3Amount;
    private BigDecimal limit3BuyRate;
    private BigDecimal limit3SellRate;
    private String status;
    private String createdAt;
    private String publishedAt;
}

package hu.puzzleir.valuta.dto.ratehistory;

import hu.puzzleir.valuta.entity.RateCategory;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RateHistoryDto {
    private Long id;
    private String currencyCode;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private BigDecimal mnbRate;
    private BigDecimal spread;
    private RateCategory.RateCategoryType category;
    private LocalDateTime effectiveFrom;
    private LocalDateTime effectiveTo;
    private Long setBy;
    private Long approvedBy;
    private UUID branchId;
    private UUID companyId;
    private LocalDateTime createdAt;
}

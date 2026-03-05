package hu.puzzleir.valuta.dto.ratecategory;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class RateCategoryDto {
    private UUID id;
    private UUID branchId;
    private String currencyCode;
    private String category;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private BigDecimal minAmount;
    private BigDecimal maxAmount;
    private LocalDateTime validFrom;
    private LocalDateTime validTo;
}

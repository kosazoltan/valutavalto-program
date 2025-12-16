package hu.puzzleir.valuta.dto.denomination;

import hu.puzzleir.valuta.entity.DenominationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Címlet DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DenominationDto {
    private Long id;

    // Iroda
    private String branchId;
    private String branchName;

    // Valuta
    private Long currencyId;
    private String currencyCode;
    private String currencyName;

    // Címlet adatok
    private BigDecimal faceValue;
    private DenominationType denominationType;
    private Integer quantity;
    private BigDecimal totalValue;

    // Limitek
    private Integer minQuantity;
    private Integer maxQuantity;
    private boolean lowStock;

    private Boolean active;
    private LocalDateTime updatedAt;
}

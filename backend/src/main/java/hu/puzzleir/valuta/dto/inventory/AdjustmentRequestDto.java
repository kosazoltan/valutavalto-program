package hu.puzzleir.valuta.dto.inventory;

import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;

/**
 * Manuális készlet korrekció kérés (supervisor only)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdjustmentRequestDto {
    @NotNull
    private String branchId;
    @NotNull
    private Long currencyId;
    @NotNull
    private BigDecimal newAmount;
    @NotNull
    private String reason;
    private String notes;
}

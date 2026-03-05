package hu.puzzleir.valuta.dto.inventory;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CorrectionRequestDto {
    @NotNull private String branchId;
    @NotNull private Long currencyId;
    @NotNull @PositiveOrZero private BigDecimal newAmount;
    @NotBlank private String reason;
}

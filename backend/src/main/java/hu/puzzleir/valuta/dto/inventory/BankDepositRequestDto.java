package hu.puzzleir.valuta.dto.inventory;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BankDepositRequestDto {
    @NotNull private String branchId;
    @NotNull private Long currencyId;
    @NotNull @Positive private BigDecimal amount;
    private String notes;
}

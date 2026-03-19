package hu.puzzleir.valuta.dto.transfer;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateTransferDto {
    @NotNull private String toBranchId;
    @NotNull private Long currencyId;
    @NotNull @Positive private BigDecimal amount;
    private BigDecimal hufValue;
    @NotNull private String transferType;
    /** Átadás iránya: F, U, UF, FF (default: UF) */
    private String direction;
    private String notes;
}

package hu.puzzleir.valuta.dto.inventory;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReceiveMovementDto {
    @NotNull @Positive private BigDecimal receivedAmount;
}

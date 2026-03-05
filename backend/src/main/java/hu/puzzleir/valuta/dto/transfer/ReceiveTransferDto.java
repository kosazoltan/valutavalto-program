package hu.puzzleir.valuta.dto.transfer;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReceiveTransferDto {
    @NotNull @Positive private BigDecimal receivedAmount;
    private String notes;
}

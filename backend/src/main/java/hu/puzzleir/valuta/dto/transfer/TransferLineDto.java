package hu.puzzleir.valuta.dto.transfer;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.*;

import java.math.BigDecimal;

/**
 * Átadás-átvétel egy valuta-sora (#6). Kéréskor currencyId + amount; válaszkor
 * a kód/név/fogadott összeg is kitöltve.
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransferLineDto {
    @NotNull
    private Long currencyId;
    @NotNull @Positive
    private BigDecimal amount;

    // Válasz-mezők (createnél nem kötelező)
    private String currencyCode;
    private String currencyName;
    private BigDecimal receivedAmount;
    private BigDecimal difference;
    private Integer lineNo;
}

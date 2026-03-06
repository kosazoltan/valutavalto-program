package hu.puzzleir.valuta.dto.trade;

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ProposeTradeDto {
    @NotNull(message = "Forrás iroda kötelező")
    private UUID fromBranchId;

    @NotNull(message = "Cél iroda kötelező")
    private UUID toBranchId;

    @NotBlank(message = "Valutakód kötelező")
    @Size(min = 3, max = 3, message = "Valutakód 3 karakteres")
    private String currencyCode;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek pozitívnak kell lennie")
    private BigDecimal amount;

    @NotNull(message = "Árfolyam kötelező")
    @DecimalMin(value = "0.0001", message = "Az árfolyamnak pozitívnak kell lennie")
    private BigDecimal rate;

    @Size(max = 500, message = "Megjegyzés max 500 karakter")
    private String notes;
}

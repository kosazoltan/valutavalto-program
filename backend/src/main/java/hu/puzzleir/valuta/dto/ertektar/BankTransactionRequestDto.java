package hu.puzzleir.valuta.dto.ertektar;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.*;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BankTransactionRequestDto {

    @NotBlank(message = "Tranzakció típus kötelező (BUY/SELL)")
    @Pattern(regexp = "BUY|SELL", message = "Érvényes típus: BUY vagy SELL")
    private String transactionType;

    @NotBlank(message = "Valutakód kötelező")
    private String currencyCode;

    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek pozitívnak kell lennie")
    private BigDecimal amount;

    @NotNull(message = "Árfolyam kötelező")
    @DecimalMin(value = "0.0001", message = "Az árfolyamnak pozitívnak kell lennie")
    private BigDecimal exchangeRate;

    private Integer vaultTerritoryId;
    private String bankName;
    private String bankReference;
    private String note;
}

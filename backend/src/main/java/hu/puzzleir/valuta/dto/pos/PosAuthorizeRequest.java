package hu.puzzleir.valuta.dto.pos;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

public record PosAuthorizeRequest(
        @NotBlank(message = "A terminalId kötelező")
        @Pattern(regexp = "^[A-Za-z0-9._-]{1,64}$", message = "A terminalId formátuma érvénytelen")
        String terminalId,

        @NotNull(message = "Az amount kötelező")
        @Positive(message = "Az amount értéke legyen nagyobb mint 0")
        BigDecimal amount,

        @Pattern(regexp = "^[A-Z]{3}$", message = "A currency 3 nagybetűs ISO kód legyen")
        String currency
) {
    public String normalizedCurrency() {
        return currency == null || currency.isBlank() ? "HUF" : currency.trim().toUpperCase();
    }
}

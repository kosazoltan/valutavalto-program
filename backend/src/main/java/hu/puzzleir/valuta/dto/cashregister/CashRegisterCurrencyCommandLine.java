package hu.puzzleir.valuta.dto.cashregister;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashRegisterCurrencyCommandLine {

    @Pattern(regexp = "^[A-Za-z]{3}$", message = "currencyCode 3 betűs ISO kód kell legyen")
    private String currencyCode;

    @Size(max = 40)
    private String displayName;

    @Pattern(regexp = "^[A-Za-z0-9]{2,8}$", message = "cashRegisterKey csak 2-8 alfanumerikus karakter lehet")
    private String cashRegisterKey;

    @DecimalMin(value = "0.0001", message = "rate pozitív kell legyen")
    private BigDecimal rate;
}

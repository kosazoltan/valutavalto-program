package hu.puzzleir.valuta.dto.exchangerate;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Árfolyam létrehozás DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateExchangeRateDto {

    @NotNull(message = "Valuta azonosító kötelező")
    private Long currencyId;

    private UUID branchId; // null = céges szintű

    @NotNull(message = "Vételi árfolyam kötelező")
    @DecimalMin(value = "0.01", message = "A vételi árfolyamnak nagyobbnak kell lennie 0-nál")
    private BigDecimal baseBuyRate;

    @NotNull(message = "Eladási árfolyam kötelező")
    @DecimalMin(value = "0.01", message = "Az eladási árfolyamnak nagyobbnak kell lennie 0-nál")
    private BigDecimal baseSellRate;

    // Limit 1 (pl. 100.000 Ft felett)
    private BigDecimal limit1Amount;
    private BigDecimal limit1BuyRate;
    private BigDecimal limit1SellRate;

    // Limit 2 (pl. 500.000 Ft felett)
    private BigDecimal limit2Amount;
    private BigDecimal limit2BuyRate;
    private BigDecimal limit2SellRate;

    // Limit 3 (pl. 1.000.000 Ft felett)
    private BigDecimal limit3Amount;
    private BigDecimal limit3BuyRate;
    private BigDecimal limit3SellRate;

    // MNB árfolyam
    private BigDecimal officialRate;
}

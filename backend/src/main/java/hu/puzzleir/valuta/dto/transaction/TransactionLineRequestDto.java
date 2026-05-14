package hu.puzzleir.valuta.dto.transaction;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Bizonylat tetelsor request DTO (BLOKKTETEL input)
 * Legacy: max 6 sor / bizonylat
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionLineRequestDto {

    /** Valuta ID (alternativa a currencyCode-hoz) */
    private Long currencyId;

    /** Valuta kod (pl. EUR, USD) */
    private String currencyCode;

    /** Bankjegy darabszam / valuta osszeg */
    @NotNull(message = "Bankjegy darabszam kotelezo")
    @DecimalMin(value = "0.01", message = "A darabszamnak nagyobbnak kell lennie 0-nal")
    private BigDecimal banknoteCount;

    /** Egyedi arfolyam (opcionalis — ha null, az aktualis arfolyamot hasznaljuk) */
    @DecimalMin(value = "0.0001", message = "Az egyedi arfolyamnak pozitivnak kell lennie")
    private BigDecimal customExchangeRate;

    /** Sor kedvezmeny tipus (0=nincs, 4=VIP, stb.) */
    private Integer discountType;

    /**
     * Devizastatusz tetel-szinten (V226, 2026-05-14):
     * DOMESTIC (belfoldi) / FOREIGN (kulfoldi). Case-insensitive.
     *
     * <p>Ha NULL, a parent BuyRequest/SellRequest foreignStatus erteke orokitt at.
     * Igy a regi kliens (ami csak fejlec-szintu erteket kuld) ne tornek meg.</p>
     */
    @Pattern(regexp = "^(?i)(DOMESTIC|FOREIGN)?$",
            message = "Érvénytelen tetel-szintu devizastátusz — csak DOMESTIC vagy FOREIGN engedélyezett")
    private String foreignStatus;
}

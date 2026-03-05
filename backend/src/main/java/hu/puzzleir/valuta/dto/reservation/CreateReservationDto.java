package hu.puzzleir.valuta.dto.reservation;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Foglaló létrehozás DTO.
 *
 * Legacy: FoglaloBevetelezes — ügyfél befizet HUF-ban, rendszer lefoglalja a valutát.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateReservationDto {

    /** Ügyfél azonosító */
    @NotNull(message = "Ügyfél azonosító kötelező")
    private Long customerId;

    /** Valuta kód (ISO 4217: EUR, USD, GBP, stb.) */
    @NotBlank(message = "Valuta kód kötelező")
    @Size(min = 3, max = 3, message = "Valuta kód pontosan 3 karakter")
    private String currencyCode;

    /** Lefoglalandó valuta mennyiség */
    @NotNull(message = "Összeg kötelező")
    @DecimalMin(value = "0.01", message = "Az összegnek nagyobbnak kell lennie 0-nál")
    private BigDecimal amount;

    /** Alkalmazott árfolyam */
    @NotNull(message = "Árfolyam kötelező")
    @DecimalMin(value = "0.0001", message = "Az árfolyamnak nagyobbnak kell lennie 0-nál")
    private BigDecimal exchangeRate;

    /** Foglaló lejárati időpontja */
    @NotNull(message = "Lejárati idő kötelező")
    private LocalDateTime expiresAt;

    /** Megjegyzés (opcionális) */
    @Size(max = 1000, message = "Megjegyzés max 1000 karakter")
    private String notes;
}

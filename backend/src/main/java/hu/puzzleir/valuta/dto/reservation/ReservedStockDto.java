package hu.puzzleir.valuta.dto.reservation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Foglalt készlet DTO — valutanemenként.
 *
 * Legacy mapping: FOGLALOKESZLET tábla
 * Egy irodában lévő aktív foglalók összesítve valutanemenként.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReservedStockDto {

    /** Valuta kód (ISO 4217) */
    private String currencyCode;

    /** Foglalt mennyiség (aktív foglalók összege) */
    private BigDecimal reservedAmount;

    /** Aktív foglalók száma ebben a valutában */
    private Long activeCount;
}

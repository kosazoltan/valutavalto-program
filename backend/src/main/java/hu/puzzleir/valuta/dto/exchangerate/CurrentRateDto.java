package hu.puzzleir.valuta.dto.exchangerate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Egyszerűsített árfolyam DTO a POS kliens számára.
 *
 * Pontosan a frontend ExchangeRate TypeScript típusra képez:
 * { currencyCode, buyRate, sellRate, unit, updatedAt }
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CurrentRateDto {
    private String currencyCode;
    private BigDecimal buyRate;
    private BigDecimal sellRate;
    private int unit;
    private String updatedAt;
}

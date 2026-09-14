package hu.puzzleir.valuta.dto.currency;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Valuta DTO - válasz
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CurrencyDto {
    private Long id;
    private String code;
    private String name;
    private String symbol;
    private Integer decimals;
    private Integer displayOrder;
    private Boolean active;
    /** FK13 (FR-9): vételi oldali "0 engedélyezett" jelölő (NULL = nem beállított = tiltott). */
    private Boolean buyZeroAllowed;
    /** FK13 (FR-9): eladási oldali "0 engedélyezett" jelölő (NULL = nem beállított = tiltott). */
    private Boolean sellZeroAllowed;
}

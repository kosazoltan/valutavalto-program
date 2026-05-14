package hu.puzzleir.valuta.dto.transaction;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Bizonylat tetelsor DTO (BLOKKTETEL)
 * Legacy: max 6 sor / bizonylat
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TransactionLineDto {

    private Long id;

    /** Sor sorszama (1-6) */
    private Integer lineNumber;

    /** Valuta ID */
    private Long currencyId;

    /** Valuta kod (pl. EUR, USD) */
    private String currencyCode;

    /** Valuta nev */
    private String currencyName;

    /** Alkalmazott arfolyam */
    private BigDecimal appliedRate;

    /** Eredeti (kedvezmeny elotti) arfolyam */
    private BigDecimal originalRate;

    /** Bankjegy darabszam (valuta osszeg) */
    private BigDecimal banknoteCount;

    /** Forint ertek */
    private BigDecimal hufValue;

    /** Sor kedvezmeny osszeg (Ft) */
    private BigDecimal lineDiscount;

    /** Kedvezmeny tipus (0=nincs, 4=VIP, stb.) */
    private Integer discountType;

    /**
     * Devizastatusz tetel-szinten (V226, 2026-05-14): DOMESTIC (belfoldi) / FOREIGN (kulfoldi).
     * NULL ha nincs megadva. A bizonylat sablon tetelenkent jeleniti meg.
     */
    private String foreignStatus;
}

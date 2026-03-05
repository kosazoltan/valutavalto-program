package hu.puzzleir.valuta.dto.aml;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * AML ellenőrzés eredménye a legacy BIGCTRL.DLL TranzTipus logika alapján.
 *
 * TranzTipus értékek:
 *  6  = hasforint >= 50M (kiemelt figyelmet igénylő)
 *  5  = hasforint >= 10M (fokozott figyelmet igénylő)
 *  4  = negyedév alatt 4+ tranzakció ÉS negyedévFt >= 25M
 *  3  = évi max >= 8M ÉS aktuális >= 8M (éves ismétlődő)
 *  2  = külföldi ügyfél
 *  1  = belföldi kiemelt közszereplő (PEP)
 * -1  = külföldi, nem kaphat USD-t
 *  0  = normál (nincs kiemelt besorolás)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlCheckResult {

    /**
     * Legacy TranzTipus: -1, 0, 1, 2, 3, 4, 5, 6
     */
    private int transactionType;

    /**
     * Heti göngyölt összeg (elmúlt 7 nap HUF)
     */
    private BigDecimal weeklyTotal;

    /**
     * Éves maximum tranzakció összeg (adott év)
     */
    private BigDecimal yearlyMax;

    /**
     * Negyedéves tranzakciószám
     */
    private int quarterlyCount;

    /**
     * Negyedéves összeg HUF
     */
    private BigDecimal quarterlyTotal;

    /**
     * Kötelező személyazonosítás
     */
    private boolean requiresId;

    /**
     * Fokozott átvilágítás szükséges
     */
    private boolean requiresEnhanced;

    /**
     * Tranzakció blokkolva (pl. külföldi + USD)
     */
    private boolean blocked;

    /**
     * Figyelmeztetések listája
     */
    @Builder.Default
    private List<String> warnings = new ArrayList<>();
}

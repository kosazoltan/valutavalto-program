package hu.puzzleir.valuta.dto.aml;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * AML ellenorzes eredmenye a legacy BIGCTRL.DLL TranzTipus logika alapjan.
 *
 * TranzTipus ertekek:
 *  6  = hasforint >= 50M (kiemelt figyelmet igenylo)
 *  5  = hasforint >= 10M (fokozott figyelmet igenylo)
 *  4  = negyedev alatt 4+ tranzakcio ES negyedevFt >= 25M
 *  3  = evi max >= 8M ES aktualis >= 8M (eves ismetlodo)
 *  2  = kulfoldi ugyfel
 *  1  = belfoldi kiemelt kozszereplo (PEP)
 * -1  = kulfoldi, nem kaphat USD-t
 *  0  = normal (nincs kiemelt besorolas)
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
     * Heti gongyolt osszeg (elmult 7 nap HUF)
     */
    private BigDecimal weeklyTotal;

    /**
     * Eves maximum tranzakcio osszeg (adott ev)
     */
    private BigDecimal yearlyMax;

    /**
     * Negyedeves tranzakcioszam
     */
    private int quarterlyCount;

    /**
     * Negyedeves osszeg HUF
     */
    private BigDecimal quarterlyTotal;

    /**
     * Kotelezo szemelyazonositas
     */
    private boolean requiresId;

    /**
     * Fokozott atvilagitas szukseges
     */
    private boolean requiresEnhanced;

    /**
     * Tranzakcio blokkolva (pl. kulfoldi + USD) - HARD BLOCK, nem override-olhato.
     */
    private boolean blocked;

    /**
     * Sprint 5.3 C2 - 8 napos gordulo limit tullepve.
     * A Pmt. (2017. LIII. tv.) szerinti fokozott atvilagitasi kuszob
     * (4.500.000 Ft a rolling 8 napos ablakban).
     */
    private boolean rollingWindowExceeded;

    /**
     * Sprint 5.3 - 8 napos gordulo ablak limit (HUF).
     */
    private BigDecimal rollingWindowLimit;

    /**
     * Sprint 5.3 - 8 napos gordulo ablak aktualis osszege (HUF, aktualis tx-szel egyutt).
     */
    private BigDecimal rollingWindowTotal;

    /**
     * Sprint 5.3 - Az ablak hossza napokban (legacy BIGCTRL: 8).
     */
    private int rollingWindowDays;

    /**
     * Sprint 5.3 - SUPERVISOR/MANAGER jovahagyas kotelezo (soft block).
     * A tranzakcio NEM haladhat tovabb a workflow-n jovahagyas nelkul.
     */
    private boolean requiresManagerApproval;

    /**
     * Sprint 5.3 - Manager jovahagyasi indok (ha requiresManagerApproval=true).
     */
    private String managerApprovalReason;

    /**
     * Figyelmeztetesek listaja
     */
    @Builder.Default
    private List<String> warnings = new ArrayList<>();
}

package hu.puzzleir.valuta.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

/**
 * FK-047: Napi ellenőrző lista grid — egy valuta összesített napi mérleg-sora.
 *
 * <p>A pénztári adatokat az FK-046 tölti a {@code daily_balance} táblába; ez a DTO a
 * kiválasztott scope-on (teljes cég / terület / pénztár) VALUTÁNKÉNT összesített
 * értékeket adja. A TÖBB/HIÁNY a TH-tranzakcióból számolt {@code surplus}/{@code shortage}
 * mező (NEM a matematikai {@code difference}) — FR-6.</p>
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DailyBalanceGridRowDto {

    private String currencyCode;

    private BigDecimal openingBalance;

    private BigDecimal purchases;

    private BigDecimal sales;

    private BigDecimal transfersIn;

    private BigDecimal transfersOut;

    private BigDecimal closingBalance;

    /** Pénztári SZÁMZÁR (fizikai leszámolás) — null, ha az adott napon nincs rögzítve. */
    private BigDecimal actualStock;

    /** Értéktári banki átvétel (BANK+) — null, ha a scope-ban nincs értéktári mérleg-sor a valutára. */
    private BigDecimal bankPlus;

    /** Értéktári banki átadás (BANK−) — null, ha a scope-ban nincs értéktári mérleg-sor a valutára. */
    private BigDecimal bankMinus;

    /** TH-tranzakcióból számolt többlet (FR-6). */
    private BigDecimal surplus;

    /** TH-tranzakcióból számolt hiány (FR-6). */
    private BigDecimal shortage;
}

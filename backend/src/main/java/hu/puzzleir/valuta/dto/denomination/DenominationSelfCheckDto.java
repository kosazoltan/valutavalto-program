package hu.puzzleir.valuta.dto.denomination;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * FK-078 FR-4: napkozbeni onellenorzes egy penznemre — a becimletezett osszeg es a
 * {@code cash_balance.currentBalance} osszevetese.
 *
 * <p>Kizarolag TAJEKOZTATO jellegu: a mentes soha nem blokkolodik az eredmenye alapjan
 * (FK-078 Scope OUT — a blokkolo zaras-kapu kulon, jovobeli keres).</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DenominationSelfCheckDto {

    /** Penznem kod (pl. HUF, EUR). */
    private String currencyCode;

    /** A penznem {@code currency.id}-ja — a frontend igy tudja a sort a valutahoz kotni. */
    private Long currencyId;

    /** A mai napra, az adott kategoriaban becimletezett osszeg (denomination_balance). */
    private BigDecimal denominatedAmount;

    /** A kassza konyv szerinti egyenlege (cash_balance.currentBalance). */
    private BigDecimal expectedBalance;

    /** denominatedAmount - expectedBalance (elojeles: pozitiv = tobblet). */
    private BigDecimal difference;

    /** TRUE, ha a ket osszeg pontosan egyezik (2 tizedesre kerekitve osszevetve). */
    private boolean matches;
}

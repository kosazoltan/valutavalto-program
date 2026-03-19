package hu.puzzleir.valuta.dto.rate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Egy valutanem összes árfolyam-típusa a legacy GETARF fájlból kiolvasva.
 *
 * A 9 árfolyam-típust tárolja BigDecimal formátumban (már leosztva 100-zal,
 * JPY esetén 1000-rel).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ParsedCurrencyRate {

    /** ISO 4217 valutakód (pl. EUR, USD, JPY) */
    private String currencyCode;

    /** 1. Vételi árfolyam */
    private BigDecimal buyRate;

    /** 2. Eladási árfolyam */
    private BigDecimal sellRate;

    /** 3. MNB közép árfolyam */
    private BigDecimal mnbRate;

    /** 4. Kedvezményes vételi */
    private BigDecimal discountBuy;

    /** 5. Kedvezményes eladási */
    private BigDecimal discountSell;

    /** 6. F1 vételi */
    private BigDecimal f1Buy;

    /** 7. F1 eladási */
    private BigDecimal f1Sell;

    /** 8. Főértéktáros vételi */
    private BigDecimal chiefTreasurerBuy;

    /** 9. Főértéktáros eladási */
    private BigDecimal chiefTreasurerSell;
}

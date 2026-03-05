package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Bizonylat tétel sor (max 6 sor/bizonylat).
 *
 * Legacy mapping: BLOKKTETEL tábla
 * - VALUTANEM: valuta kód
 * - ARFOLYAM: alkalmazott árfolyam
 * - BANKJEGY: bankjegy darabszám
 * - FOINTERTEK: forint érték
 * - SORENGEDMENY: sor kedvezmény
 * - ELSZARFOLYAM: elszámolási árfolyam
 *
 * A legacy rendszerben egy bizonylaton max 6 különböző valuta lehetett.
 * Minden sor = egy valutanem + darabszám + árfolyam + forint érték.
 */
@Entity
@Table(name = "transaction_line", indexes = {
    @Index(name = "idx_txline_transaction", columnList = "transaction_id"),
    @Index(name = "idx_txline_currency", columnList = "currency_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TransactionLine {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Szülő tranzakció (bizonylat fejléc)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    private Transaction transaction;

    /**
     * Sor sorszáma (1-6)
     * Legacy: a BLOKKTETEL sorrendje
     */
    @Column(name = "line_number", nullable = false)
    private Integer lineNumber;

    /**
     * Valutanem
     * Legacy: VALUTANEM
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Alkalmazott árfolyam (fillérre pontosan)
     * Legacy: ARFOLYAM (integer, pl. 39850 = 398.50 Ft/EUR)
     *
     * A legacy rendszerben az árfolyam 100-zal szorzott integer volt.
     * Pl. EUR eladás = 39850 → valójában 398.50 Ft
     * A számítás: forint = árfolyam / 100 * bankjegy_darab
     * JPY esetén: forint = árfolyam / 1000 * bankjegy_darab
     */
    @Column(name = "applied_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal appliedRate;

    /**
     * Eredeti (kedvezmény előtti) árfolyam
     * Legacy: _wOrigArfolyam
     */
    @Column(name = "original_rate", precision = 12, scale = 4)
    private BigDecimal originalRate;

    /**
     * Elszámolási (MNB) árfolyam
     * Legacy: ELSZARFOLYAM / _wElszamolasi
     */
    @Column(name = "settlement_rate", precision = 12, scale = 4)
    private BigDecimal settlementRate;

    /**
     * Bankjegy darabszám
     * Legacy: BANKJEGY / _aktBankjegy
     */
    @Column(name = "banknote_count", nullable = false, precision = 15, scale = 2)
    private BigDecimal banknoteCount;

    /**
     * Forint érték (számított)
     * Legacy: FOINTERTEK / _aktErtek
     *
     * Számítás: appliedRate / 100 * banknoteCount
     * JPY: appliedRate / 1000 * banknoteCount
     */
    @Column(name = "huf_value", nullable = false, precision = 15, scale = 0)
    private BigDecimal hufValue;

    /**
     * Sor kedvezmény összeg (Ft)
     * Legacy: SORENGEDMENY
     */
    @Column(name = "line_discount", precision = 15, scale = 0)
    @Builder.Default
    private BigDecimal lineDiscount = BigDecimal.ZERO;

    /**
     * Kedvezmény típusa (0=nincs, 4=VIP, 20=F1, 32=főértéktáros, 33=értéktáros, 34=jutalékmentes)
     * Legacy: _kedvWord
     */
    @Column(name = "discount_type")
    @Builder.Default
    private Integer discountType = 0;

    // ============ HELPER METHODS ============

    /**
     * Legacy-kompatibilis forint számítás.
     *
     * A régi rendszerben: _aktErtek = round((_aktArfolyam / 100 * _aktBankjegy) + 0.001)
     * JPY esetén: _aktErtek = round(_aktErtek / 10)
     *
     * @param currencyCode valutanem kód (JPY speciális kezelés)
     */
    public BigDecimal calculateHufValue(String currencyCode) {
        BigDecimal divisor = "JPY".equals(currencyCode)
            ? new BigDecimal("1000")
            : new BigDecimal("100");
        return appliedRate.divide(divisor).multiply(banknoteCount)
            .setScale(0, java.math.RoundingMode.HALF_UP);
    }

    /**
     * Nettó forint érték (kedvezmény után)
     */
    public BigDecimal getNetHufValue() {
        return hufValue.subtract(lineDiscount != null ? lineDiscount : BigDecimal.ZERO);
    }
}

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

    /**
     * Devizastatusz tetel-szinten (V226 migracio, 2026-05-14):
     * DOMESTIC (belfoldi) / FOREIGN (kulfoldi).
     *
     * <p>User-direktiva: egy bizonylaton tetelenkent kulonbozo statusz lehet
     * (pl. 2 EUR FOREIGN + 1 USD DOMESTIC). A bizonylat generator (Receipt) tetelsoronkent
     * jelenit meg.</p>
     *
     * <p>Backfill: parent Transaction.foreignStatus erteke.</p>
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "foreign_status", length = 10)
    private ForeignStatus foreignStatus;

    // ============ HELPER METHODS ============

    /**
     * Sor forint-értéke = alkalmazott árfolyam × bankjegy-mennyiség, egész forintra kerekítve.
     *
     * <p><b>CRITICAL FIX (Codex P1, 2026-06-04 — adverzariális money-review):</b> a korábbi
     * {@code appliedRate / 100} (JPY {@code / 1000}) osztó egy LEGACY Delphi ráta-konvenció maradványa volt
     * (ott a ráta per-100-egység: {@code _aktArfolyam / 100 * _aktBankjegy}). A MODERN rendszer árfolyamai
     * azonban PER-EGYSÉG kvótáltak (pl. EUR baseBuyRate=392.16 / 1 EUR), és a single-line út
     * {@code currencyAmount × appliedRate} osztó NÉLKÜL számol. Az osztó tehát 100×/1000×-rel ALULTARIFÁLTA a
     * multi-line sorokat (EUR 100 @ 390 → 390 Ft a helyes 39.000 Ft helyett). Mivel a multi-line út élesben
     * eddig nem futott (a pénztáros single-line tranzakciókat küldött), a hiba lappangott; az aggregát-
     * submission bekötésekor derült ki. Az osztó eltávolítva → egyezik a single-line és a per-egység ráta-
     * konvencióval.</p>
     */
    public BigDecimal calculateHufValue() {
        return appliedRate
            .multiply(banknoteCount)
            .setScale(0, java.math.RoundingMode.HALF_UP);
    }

    /**
     * Nettó forint érték (kedvezmény után)
     */
    public BigDecimal getNetHufValue() {
        return hufValue.subtract(lineDiscount != null ? lineDiscount : BigDecimal.ZERO);
    }
}

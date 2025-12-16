package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Árfolyam entity - napi/aktuális árfolyamok.
 *
 * Legacy mapping: ARFOLYAM tábla
 * - DATUM, IDO: dátum és időpont
 * - VALUTANEM: valuta kód
 * - ALAPVETEL, ALAPELADAS: alap árfolyamok
 * - LIM1VETEL, LIM1ELADAS, LIMIT1: limit 1 árfolyamok és összeghatár
 * - LIM2VETEL, LIM2ELADAS, LIMIT2: limit 2 árfolyamok és összeghatár
 * - LIMIT3: limit 3 összeghatár
 * - ELSZAMOLASIARFOLYAM: MNB hivatalos árfolyam
 */
@Entity
@Table(name = "exchange_rate", indexes = {
    @Index(name = "idx_exchange_rate_date", columnList = "valid_date, valid_time"),
    @Index(name = "idx_exchange_rate_currency", columnList = "currency_id"),
    @Index(name = "idx_exchange_rate_company", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExchangeRate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Opcionális: Fiók-specifikus árfolyam
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id")
    private Branch branch;

    /**
     * Valutanem
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Érvényesség dátuma
     * Legacy: DATUM
     */
    @Column(name = "valid_date", nullable = false)
    private LocalDate validDate;

    /**
     * Érvényesség időpontja (napközbeni árfolyam változás)
     * Legacy: IDO
     */
    @Column(name = "valid_time", nullable = false)
    private LocalTime validTime;

    // ============ ALAP ÁRFOLYAMOK ============

    /**
     * Alap vételi árfolyam (bank vesz valutát, ad forintot)
     * Legacy: ALAPVETEL
     */
    @Column(name = "base_buy_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal baseBuyRate;

    /**
     * Alap eladási árfolyam (bank elad valutát, kap forintot)
     * Legacy: ALAPELADAS
     */
    @Column(name = "base_sell_rate", nullable = false, precision = 12, scale = 4)
    private BigDecimal baseSellRate;

    // ============ LIMIT 1 ÁRFOLYAMOK ============

    /**
     * Limit 1 összeghatár (Ft-ban)
     * Legacy: LIMIT1
     */
    @Column(name = "limit1_amount", precision = 15, scale = 2)
    private BigDecimal limit1Amount;

    /**
     * Limit 1 vételi árfolyam
     * Legacy: LIM1VETEL
     */
    @Column(name = "limit1_buy_rate", precision = 12, scale = 4)
    private BigDecimal limit1BuyRate;

    /**
     * Limit 1 eladási árfolyam
     * Legacy: LIM1ELADAS
     */
    @Column(name = "limit1_sell_rate", precision = 12, scale = 4)
    private BigDecimal limit1SellRate;

    // ============ LIMIT 2 ÁRFOLYAMOK ============

    /**
     * Limit 2 összeghatár (Ft-ban)
     * Legacy: LIMIT2
     */
    @Column(name = "limit2_amount", precision = 15, scale = 2)
    private BigDecimal limit2Amount;

    /**
     * Limit 2 vételi árfolyam
     * Legacy: LIM2VETEL
     */
    @Column(name = "limit2_buy_rate", precision = 12, scale = 4)
    private BigDecimal limit2BuyRate;

    /**
     * Limit 2 eladási árfolyam
     * Legacy: LIM2ELADAS
     */
    @Column(name = "limit2_sell_rate", precision = 12, scale = 4)
    private BigDecimal limit2SellRate;

    // ============ LIMIT 3 ÁRFOLYAM ============

    /**
     * Limit 3 összeghatár (Ft-ban)
     * Legacy: LIMIT3
     */
    @Column(name = "limit3_amount", precision = 15, scale = 2)
    private BigDecimal limit3Amount;

    /**
     * Limit 3 vételi árfolyam
     */
    @Column(name = "limit3_buy_rate", precision = 12, scale = 4)
    private BigDecimal limit3BuyRate;

    /**
     * Limit 3 eladási árfolyam
     */
    @Column(name = "limit3_sell_rate", precision = 12, scale = 4)
    private BigDecimal limit3SellRate;

    // ============ HIVATALOS ÁRFOLYAM ============

    /**
     * MNB hivatalos árfolyam (elszámoláshoz)
     * Legacy: ELSZAMOLASIARFOLYAM
     */
    @Column(name = "official_rate", precision = 12, scale = 4)
    private BigDecimal officialRate;

    /**
     * Árfolyam aktív-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    /**
     * Ki állította be az árfolyamot
     */
    @Column(name = "created_by", length = 50)
    private String createdBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // ============ HELPER METHODS ============

    /**
     * Visszaadja a megfelelő vételi árfolyamot az összeg alapján
     */
    public BigDecimal getBuyRateForAmount(BigDecimal amountHuf) {
        if (limit3Amount != null && amountHuf.compareTo(limit3Amount) >= 0 && limit3BuyRate != null) {
            return limit3BuyRate;
        }
        if (limit2Amount != null && amountHuf.compareTo(limit2Amount) >= 0 && limit2BuyRate != null) {
            return limit2BuyRate;
        }
        if (limit1Amount != null && amountHuf.compareTo(limit1Amount) >= 0 && limit1BuyRate != null) {
            return limit1BuyRate;
        }
        return baseBuyRate;
    }

    /**
     * Visszaadja a megfelelő eladási árfolyamot az összeg alapján
     */
    public BigDecimal getSellRateForAmount(BigDecimal amountHuf) {
        if (limit3Amount != null && amountHuf.compareTo(limit3Amount) >= 0 && limit3SellRate != null) {
            return limit3SellRate;
        }
        if (limit2Amount != null && amountHuf.compareTo(limit2Amount) >= 0 && limit2SellRate != null) {
            return limit2SellRate;
        }
        if (limit1Amount != null && amountHuf.compareTo(limit1Amount) >= 0 && limit1SellRate != null) {
            return limit1SellRate;
        }
        return baseSellRate;
    }
}

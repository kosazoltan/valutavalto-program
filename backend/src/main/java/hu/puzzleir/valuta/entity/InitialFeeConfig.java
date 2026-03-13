package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Kezdőjegy (kezelési költség) konfiguráció.
 *
 * Legacy: KEZDIJ tábla
 * - Típus: alapkezdij, VIP, értéktáros engedélyével stb.
 * - A pénztáros napi kerete korlátozott (pl. 5 saját hatáskörű kedvezmény/nap)
 *
 * Kedvezmény típusok (legacy _kedvWord):
 *   0 = nincs kedvezmény
 *   4 = VIP ügyfél
 *  20 = F1-es (tábla szerinti)
 *  32 = Főértéktáros engedélyével
 *  33 = Értéktáros engedélyével
 *  34 = Jutalékmentes ügyvezető
 */
@Entity
@Table(name = "initial_fee_config", indexes = {
    @Index(name = "idx_initfee_company", columnList = "company_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InitialFeeConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Kezdőjegy neve
     */
    @Column(name = "fee_name", nullable = false, length = 100)
    private String feeName;

    /**
     * Kezdőjegy összege (Ft)
     * Legacy: _kezdij
     */
    @Column(name = "fee_amount", nullable = false, precision = 10, scale = 0)
    private BigDecimal feeAmount;

    /**
     * Minimum tranzakciós összeg (Ft) amihez jár
     * Legacy: _minkezdij
     */
    @Column(name = "min_transaction_amount", precision = 15, scale = 0)
    private BigDecimal minTransactionAmount;

    /**
     * Maximum kezdőjegy/tranzakció (Ft)
     * Legacy: _kezdijmax
     */
    @Column(name = "max_fee_amount", precision = 10, scale = 0)
    private BigDecimal maxFeeAmount;

    /**
     * Saját hatáskörű kedvezmény napi limit
     * Legacy: SHK - max 5/nap
     */
    @Column(name = "daily_discount_limit")
    @Builder.Default
    private Integer dailyDiscountLimit = 5;

    /**
     * Egyedi kezdőjegy napi limit
     * Legacy: max 3/nap
     */
    @Column(name = "daily_custom_fee_limit")
    @Builder.Default
    private Integer dailyCustomFeeLimit = 3;

    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;
}

package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Valutanem entity.
 *
 * Legacy mapping: ARFOLYAM tábla VALUTANEM mezője
 * 27 valuta támogatás: AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR,
 * GBP, HRK, HUF, ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD
 */
@Entity
@Table(name = "currency")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Currency {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ISO 4217 valutakód (pl. EUR, USD, HUF)
     */
    @Column(nullable = false, unique = true, length = 3)
    private String code;

    /**
     * Valuta neve (pl. "Euró", "Amerikai dollár")
     */
    @Column(nullable = false, length = 100)
    private String name;

    /**
     * Valuta szimbóluma (pl. €, $, Ft)
     */
    @Column(length = 10)
    private String symbol;

    /**
     * Tizedesjegyek száma (HUF=0, EUR=2, stb.)
     */
    @Column(nullable = false)
    @Builder.Default
    private Integer decimalPlaces = 2;

    /**
     * Aktív-e a valuta (kereskedhető)
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    /**
     * Alapértelmezett vételi spread (%)
     * Legacy: kedvezmény számítás alapja
     */
    @Column(name = "default_buy_spread", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal defaultBuySpread = BigDecimal.ZERO;

    /**
     * Alapértelmezett eladási spread (%)
     */
    @Column(name = "default_sell_spread", precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal defaultSellSpread = BigDecimal.ZERO;

    /**
     * Minimális tranzakciós összeg
     */
    @Column(name = "min_transaction_amount", precision = 15, scale = 2)
    private BigDecimal minTransactionAmount;

    /**
     * Maximális tranzakciós összeg
     */
    @Column(name = "max_transaction_amount", precision = 15, scale = 2)
    private BigDecimal maxTransactionAmount;

    /**
     * Megjelenítési sorrend
     */
    @Column(name = "display_order")
    @Builder.Default
    private Integer displayOrder = 100;

    /**
     * Zászló ikon URL (opcionális)
     */
    @Column(name = "flag_icon", length = 255)
    private String flagIcon;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

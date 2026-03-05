package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * NAV zárás sor — valutánkénti bontás.
 *
 * Legacy: NAVZARO.DLL valutánkénti sorok.
 */
@Entity
@Table(name = "nav_closing_line", indexes = {
    @Index(name = "idx_nav_line_closing", columnList = "nav_closing_id"),
    @Index(name = "idx_nav_line_currency", columnList = "currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NavClosingLine {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Szülő NAV zárás
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "nav_closing_id", nullable = false)
    private NavClosing navClosing;

    /**
     * Valutanem kód
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Vételi forgalom (devizában)
     */
    @Column(name = "buy_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal buyAmount = BigDecimal.ZERO;

    /**
     * Eladási forgalom (devizában)
     */
    @Column(name = "sell_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal sellAmount = BigDecimal.ZERO;

    /**
     * Vételi HUF összeg
     */
    @Column(name = "buy_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal buyHuf = BigDecimal.ZERO;

    /**
     * Eladási HUF összeg
     */
    @Column(name = "sell_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal sellHuf = BigDecimal.ZERO;

    /**
     * Kezelési díj (ennél a valutánál)
     */
    @Column(name = "handling_fee", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal handlingFee = BigDecimal.ZERO;

    /**
     * Tranzakciók száma
     */
    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;
}

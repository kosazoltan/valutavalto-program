package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Kerekítési szabály entity.
 *
 * Valutánként definiálja a kerekítési pontosságot és a kis/nagy összegek kerekítési irányát.
 */
@Entity
@Table(name = "rounding_rule", indexes = {
    @Index(name = "idx_rounding_rule_currency", columnList = "currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoundingRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Valutakód (EUR, USD, CZK, stb.)
     */
    @Column(name = "currency_code", nullable = false, unique = true, length = 3)
    private String currencyCode;

    /**
     * Kerekítési pontosság (pl. 0.01, 0.1, 1)
     */
    @Column(name = "precision_value", nullable = false, precision = 10, scale = 4)
    private BigDecimal precisionValue;

    /**
     * Kis összeg határ (ez alatt felkerekítés)
     */
    @Column(name = "small_threshold", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal smallThreshold = new BigDecimal("100");

    /**
     * Nagy összeg határ (ez felett lefelé kerekítés)
     */
    @Column(name = "large_threshold", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal largeThreshold = new BigDecimal("10000");

    /**
     * Kis összegek kerekítési iránya (UP, DOWN, HALF_UP)
     */
    @Column(name = "small_rounding", nullable = false, length = 10)
    @Builder.Default
    private String smallRounding = "UP";

    /**
     * Nagy összegek kerekítési iránya (UP, DOWN, HALF_UP)
     */
    @Column(name = "large_rounding", nullable = false, length = 10)
    @Builder.Default
    private String largeRounding = "DOWN";
}

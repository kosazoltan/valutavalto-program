package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;

/**
 * Kezelési díj sáv definíció.
 *
 * Legacy: _tranzsav[1..23] és _kdij[1..23] tömbök
 * - _tranzsav[i] = sáv felső határa (Ft-ban)
 * - _kdij[i] = a sávhoz tartozó kezelési díj (Ft-ban)
 *
 * Példa:
 *   sáv 1: 0 - 50.000 Ft → díj: 300 Ft
 *   sáv 2: 50.001 - 100.000 Ft → díj: 500 Ft
 *   sáv 3: 100.001 - 200.000 Ft → díj: 800 Ft
 *   stb.
 */
@Entity
@Table(name = "handling_fee_bracket", indexes = {
    @Index(name = "idx_fee_bracket_company", columnList = "company_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class HandlingFeeBracket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Sáv sorszáma (1-23, a legacy rendszerből)
     */
    @Column(name = "bracket_order", nullable = false)
    private Integer bracketOrder;

    /**
     * Sáv felső határa (Ft-ban). A sáv alsó határa az előző sáv felső határa + 1.
     * Legacy: _tranzsav[i]
     */
    @Column(name = "upper_limit", nullable = false, precision = 15, scale = 0)
    private BigDecimal upperLimit;

    /**
     * Kezelési díj ebben a sávban (Ft-ban)
     * Legacy: _kdij[i]
     */
    @Column(name = "fee_amount", nullable = false, precision = 15, scale = 0)
    private BigDecimal feeAmount;

    /**
     * Aktív-e
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    /**
     * FK-096/FR-3: közzétételi állapot — ORTOGONÁLIS az active-re (a V227
     * trg_sync_active_columns trigger az active/is_active párosért felel).
     * DRAFT = még nem publikált piszkozat-készlet; LIVE = éles sávok.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 10)
    @Builder.Default
    private FeeConfigStatus status = FeeConfigStatus.LIVE;

    /**
     * FK-096 ITEM 3: sáv-sor invariáns. A sáv felső határa pozitív, a díj nemnegatív —
     * a NOT NULL oszlopokra (upper_limit, fee_amount) SOHA nem juthat el null.
     */
    public void assertValid() {
        if (upperLimit == null || upperLimit.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("A sáv felső határa kötelező és pozitív kell legyen.");
        }
        if (feeAmount == null || feeAmount.compareTo(BigDecimal.ZERO) < 0) {
            throw new ValidationException("A sáv díja kötelező és nem lehet negatív.");
        }
    }
}

package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Címletezési szabály — meghatározza, melyik OptimizationStrategy-t alkalmazza
 * a rendszer egy adott tranzakcióhoz.
 *
 * <p>v2.0 specifikáció (07_cimletkezeles.md):
 * <ul>
 *   <li>Több szabály prioritás szerint kiértékelve</li>
 *   <li>Branch-specifikus szabály felüljárja az általánost</li>
 *   <li>JSON `rule_config` mező extra paraméterekhez</li>
 *   <li>Min/max amount tartomány AMOUNT_BASED esetén</li>
 * </ul></p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1 (P1-B).</p>
 */
@Entity
@Table(name = "denomination_rule", indexes = {
    @Index(name = "idx_denom_rule_branch", columnList = "branch_id"),
    @Index(name = "idx_denom_rule_type", columnList = "rule_type"),
    @Index(name = "idx_denom_rule_currency", columnList = "currency_id"),
    @Index(name = "idx_denom_rule_active_priority", columnList = "is_active,priority")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DenominationRule {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Szabály név (egyedi). */
    @Column(name = "rule_name", nullable = false, length = 150, unique = true)
    private String ruleName;

    /** Devizanem (opcionális — null = minden valuta). */
    @Column(name = "currency_id")
    private Long currencyId;

    /** Szabály típusa (FIXED, AMOUNT_BASED, CUSTOMER_TYPE, ...). */
    @Enumerated(EnumType.STRING)
    @Column(name = "rule_type", nullable = false, length = 30)
    private DenominationRuleType ruleType;

    /** Minimum HUF összeg (AMOUNT_BASED-hez). */
    @Column(name = "min_amount", precision = 15, scale = 2)
    private BigDecimal minAmount;

    /** Maximum HUF összeg (AMOUNT_BASED-hez). */
    @Column(name = "max_amount", precision = 15, scale = 2)
    private BigDecimal maxAmount;

    /** Fiók ID (BRANCH_DEFAULT vagy fiók-specifikus szabályhoz). Null = minden fiók. */
    @Column(name = "branch_id")
    private UUID branchId;

    /**
     * Használandó optimalizációs stratégia (FK DenominationOptimization-ra).
     * EAGER fetch: a `optimization` mindig szükséges (rule-matching + JSON serialization).
     * (2026-05-13 Codex P1 #566: LazyInitializationException elkerülése.)
     */
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "optimization_id", nullable = false)
    private DenominationOptimization optimization;

    /** Szabály konfigurációja JSON formátumban (extra paraméterek). */
    @Column(name = "rule_config", columnDefinition = "TEXT")
    private String ruleConfigJson;

    /** Prioritás (kisebb = fontosabb, default 100). */
    @Column(nullable = false)
    @Builder.Default
    private Integer priority = 100;

    /** Aktív-e. */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Version
    private Long version;
}

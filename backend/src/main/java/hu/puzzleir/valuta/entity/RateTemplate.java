package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "rate_template", indexes = {
    @Index(name = "idx_rate_template_wg_status", columnList = "workgroup_id, status"),
    @Index(name = "idx_rate_template_currency", columnList = "currency_id"),
    @Index(name = "idx_rate_template_company", columnList = "company_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    @Column(name = "workgroup_id", nullable = false)
    private UUID workgroupId;

    @Column(name = "base_buy_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal baseBuyRate;

    @Column(name = "base_sell_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal baseSellRate;

    @Column(name = "buy_spread", precision = 18, scale = 6)
    @Builder.Default
    private BigDecimal buySpread = BigDecimal.ZERO;

    @Column(name = "sell_spread", precision = 18, scale = 6)
    @Builder.Default
    private BigDecimal sellSpread = BigDecimal.ZERO;

    @Column(name = "rounding_rule")
    @Builder.Default
    private Integer roundingRule = 0;

    @Column(name = "official_rate", precision = 18, scale = 6)
    private BigDecimal officialRate;

    // ============ LIMIT SZINTEK (régi rendszer 3 keretértéke) ============

    @Column(name = "limit1_amount", precision = 15, scale = 2)
    private BigDecimal limit1Amount;
    @Column(name = "limit1_buy_rate", precision = 18, scale = 6)
    private BigDecimal limit1BuyRate;
    @Column(name = "limit1_sell_rate", precision = 18, scale = 6)
    private BigDecimal limit1SellRate;

    @Column(name = "limit2_amount", precision = 15, scale = 2)
    private BigDecimal limit2Amount;
    @Column(name = "limit2_buy_rate", precision = 18, scale = 6)
    private BigDecimal limit2BuyRate;
    @Column(name = "limit2_sell_rate", precision = 18, scale = 6)
    private BigDecimal limit2SellRate;

    @Column(name = "limit3_amount", precision = 15, scale = 2)
    private BigDecimal limit3Amount;
    @Column(name = "limit3_buy_rate", precision = 18, scale = 6)
    private BigDecimal limit3BuyRate;
    @Column(name = "limit3_sell_rate", precision = 18, scale = 6)
    private BigDecimal limit3SellRate;

    // ============ WORKFLOW ============

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private RateTemplateStatus status = RateTemplateStatus.DRAFT;

    @Column(name = "created_by")
    private Long createdBy;

    @Column(name = "approved_by")
    private Long approvedBy;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "published_at")
    private LocalDateTime publishedAt;

    /** Optimista zárolás (RFM concurrent szerkesztés-védelem, VV-ELVI 7.3). */
    @Version
    private Long version;

    /**
     * Árfolyam-sablon életciklus + megengedett állapotátmenetek (state machine, VV-ELVI v2 5.2).
     *
     * <p>DRAFT → APPROVED | REVOKED · APPROVED → PUBLISHED | DRAFT | REVOKED ·
     * PUBLISHED → REVOKED · REVOKED → (terminális).
     */
    public enum RateTemplateStatus {
        DRAFT, APPROVED, PUBLISHED, REVOKED;

        public java.util.Set<RateTemplateStatus> allowedTransitions() {
            return switch (this) {
                case DRAFT -> java.util.EnumSet.of(APPROVED, REVOKED);
                case APPROVED -> java.util.EnumSet.of(PUBLISHED, DRAFT, REVOKED);
                case PUBLISHED -> java.util.EnumSet.of(REVOKED);
                case REVOKED -> java.util.EnumSet.noneOf(RateTemplateStatus.class);
            };
        }

        public boolean canTransitionTo(RateTemplateStatus target) {
            return target != null && allowedTransitions().contains(target);
        }

        public boolean isTerminal() {
            return allowedTransitions().isEmpty();
        }
    }
}

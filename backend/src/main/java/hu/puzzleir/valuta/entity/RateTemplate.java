package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.EnumSet;
import java.util.Set;
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
    @JsonIgnore
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

    /**
     * Árfolyam-sablon életciklus + megengedett állapotátmenetek (state machine, VV-ELVI v2 5.2).
     *
     * <p>Az átmenettábla a tényleges service-logikát tükrözi (egyetlen igazságforrás):
     * <ul>
     *   <li>{@code DRAFT → APPROVED} — {@code RateTemplateApprovalService.approve} (csak DRAFT hagyható jóvá)</li>
     *   <li>{@code DRAFT → PUBLISHED} — {@code RatePublishService.publish} (DRAFT vagy APPROVED publikálható)</li>
     *   <li>{@code APPROVED → PUBLISHED} — {@code RatePublishService.publish}</li>
     *   <li>{@code APPROVED → REVOKED} — {@code RateTemplateApprovalService.revoke} (DRAFT NEM vonható vissza)</li>
     *   <li>{@code PUBLISHED → REVOKED} — {@code RateTemplateApprovalService.revoke}</li>
     *   <li>{@code REVOKED} → (terminális, nincs továbblépés)</li>
     * </ul>
     */
    public enum RateTemplateStatus {
        DRAFT, APPROVED, PUBLISHED, REVOKED;

        /** Előre kiszámolt, módosíthatatlan átmenethalmazok (allokáció-mentes, immutable). */
        private static final Set<RateTemplateStatus> DRAFT_TARGETS =
                Collections.unmodifiableSet(EnumSet.of(APPROVED, PUBLISHED));
        private static final Set<RateTemplateStatus> APPROVED_TARGETS =
                Collections.unmodifiableSet(EnumSet.of(PUBLISHED, REVOKED));
        private static final Set<RateTemplateStatus> PUBLISHED_TARGETS =
                Collections.unmodifiableSet(EnumSet.of(REVOKED));
        private static final Set<RateTemplateStatus> NO_TARGETS =
                Collections.unmodifiableSet(EnumSet.noneOf(RateTemplateStatus.class));

        /** Az adott állapotból megengedett cél-állapotok (state machine). */
        public Set<RateTemplateStatus> allowedTransitions() {
            return switch (this) {
                case DRAFT -> DRAFT_TARGETS;
                case APPROVED -> APPROVED_TARGETS;
                case PUBLISHED -> PUBLISHED_TARGETS;
                case REVOKED -> NO_TARGETS;
            };
        }

        /** Megengedett-e az átmenet a megadott cél-állapotba (önmagába = no-op, nem engedett). */
        public boolean canTransitionTo(RateTemplateStatus target) {
            return target != null && allowedTransitions().contains(target);
        }

        /** Terminális állapot-e (nincs további megengedett átmenet). */
        public boolean isTerminal() {
            return allowedTransitions().isEmpty();
        }
    }

    /**
     * Multi-tenant flat companyId a JSON-ban (audit 2026-05-31, P1 LazyInit).
     * A {@code company} lazy {@code @ManyToOne} + {@code @JsonIgnore}; a controller GET/approve/revoke
     * endpointjai az ENTITÁST adják vissza, OSIV=false mellett a Company-proxy szerializálása
     * {@code LazyInitializationException} 500-at dobna. Ez a flat getter a már ismert FK-ból ad
     * companyId-t lazy-betöltés nélkül (a RateWorkgroup.getCompanyId mintája, Fix #146+).
     */
    @JsonProperty("companyId")
    @Transient
    public UUID getCompanyId() {
        return company != null ? company.getId() : null;
    }
}

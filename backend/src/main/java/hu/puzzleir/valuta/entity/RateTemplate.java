package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "rate_template", indexes = {
    @Index(name = "idx_rate_template_wg_status", columnList = "workgroup_id, status"),
    @Index(name = "idx_rate_template_currency", columnList = "currency_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

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

    public enum RateTemplateStatus {
        DRAFT, APPROVED, PUBLISHED, REVOKED
    }
}

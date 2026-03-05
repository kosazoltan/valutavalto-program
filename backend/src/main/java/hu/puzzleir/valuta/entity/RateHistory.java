package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Árfolyam történet entity.
 * Minden árfolyam-változást naplóz: MNB középárfolyam, spread, kategória.
 */
@Entity
@Table(name = "rate_history", indexes = {
    @Index(name = "idx_rate_history_currency", columnList = "currency_code"),
    @Index(name = "idx_rate_history_dates", columnList = "effective_from, effective_to"),
    @Index(name = "idx_rate_history_company", columnList = "company_id"),
    @Index(name = "idx_rate_history_branch", columnList = "branch_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(name = "buy_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal buyRate;

    @Column(name = "sell_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal sellRate;

    @Column(name = "mnb_rate", precision = 18, scale = 6)
    private BigDecimal mnbRate;

    @Column(name = "spread", precision = 10, scale = 4)
    private BigDecimal spread;

    /**
     * Árfolyam kategória: SMALL, STANDARD, LARGE
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private RateCategory.RateCategoryType category = RateCategory.RateCategoryType.STANDARD;

    @Column(name = "effective_from", nullable = false)
    private LocalDateTime effectiveFrom;

    @Column(name = "effective_to")
    private LocalDateTime effectiveTo;

    /**
     * Ki állította be (worker id)
     */
    @Column(name = "set_by")
    private Long setBy;

    /**
     * Ki hagyta jóvá (worker id)
     */
    @Column(name = "approved_by")
    private Long approvedBy;

    @Column(name = "branch_id")
    private UUID branchId;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

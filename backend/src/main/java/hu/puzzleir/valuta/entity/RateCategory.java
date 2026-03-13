package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Kis/Nagy váltós árfolyam kategória.
 * SMALL: kis összegű váltás (<500 EUR egyenérték)
 * STANDARD: normál
 * LARGE: nagy összegű váltás (>5000 EUR egyenérték)
 */
@Entity
@Table(name = "rate_category", indexes = {
    @Index(name = "idx_rate_category_branch", columnList = "branch_id"),
    @Index(name = "idx_rate_category_currency", columnList = "currency_code")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_rate_category",
                      columnNames = {"branch_id", "currency_code", "category"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RateCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private RateCategoryType category = RateCategoryType.STANDARD;

    @Column(name = "buy_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal buyRate;

    @Column(name = "sell_rate", nullable = false, precision = 18, scale = 6)
    private BigDecimal sellRate;

    @Column(name = "min_amount", precision = 18, scale = 2)
    private BigDecimal minAmount;

    @Column(name = "max_amount", precision = 18, scale = 2)
    private BigDecimal maxAmount;

    @Column(name = "valid_from", nullable = false)
    private LocalDateTime validFrom;

    @Column(name = "valid_to")
    private LocalDateTime validTo;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum RateCategoryType {
        STANDARD, SMALL, LARGE
    }
}

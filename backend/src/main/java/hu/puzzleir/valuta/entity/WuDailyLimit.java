package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Western Union napi USD keret cégenként.
 *
 * <p>A napi reset úgy történik, hogy minden business date külön sort kap.
 * A tranzakciók pesszimista zárolással növelik/csökkentik a felhasznált keretet.</p>
 */
@Entity
@Table(name = "wu_daily_limit", uniqueConstraints = {
        @UniqueConstraint(name = "wu_daily_limit_company_date_currency_uq",
                columnNames = {"company_id", "business_date", "currency_code"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuDailyLimit {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "business_date", nullable = false)
    private LocalDate businessDate;

    @Column(name = "currency_code", nullable = false, length = 3)
    @Builder.Default
    private String currencyCode = "USD";

    @Column(name = "daily_limit", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal dailyLimit = new BigDecimal("10000.00");

    @Column(name = "used_amount", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal usedAmount = BigDecimal.ZERO;

    @Column(name = "reset_at")
    private LocalDateTime resetAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
        if (resetAt == null && businessDate != null) {
            resetAt = businessDate.plusDays(1).atStartOfDay();
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

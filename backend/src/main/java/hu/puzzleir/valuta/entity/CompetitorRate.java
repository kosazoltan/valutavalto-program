package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Versenytárs árfolyam entity.
 *
 * Legacy: A régi rendszerben a versenytársak árfolyamait manuálisan
 * rögzítették az árfolyam-készítő modulban összehasonlítás céljából.
 */
@Entity
@Table(name = "competitor_rates", indexes = {
    @Index(name = "idx_competitor_rate_date", columnList = "rate_date"),
    @Index(name = "idx_competitor_rate_comp", columnList = "competitor_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CompetitorRate {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "competitor_id", nullable = false)
    private Competitor competitor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    @Column(name = "buy_rate", precision = 18, scale = 6)
    private BigDecimal buyRate;

    @Column(name = "sell_rate", precision = 18, scale = 6)
    private BigDecimal sellRate;

    @Column(name = "rate_date", nullable = false)
    private LocalDate rateDate;

    @Column(length = 100)
    private String source;

    @Column(name = "created_by")
    private Long createdBy;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

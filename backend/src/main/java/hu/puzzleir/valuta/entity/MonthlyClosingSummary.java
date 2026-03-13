package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Havi zárás összesítő entity.
 *
 * Legacy: NAPZAR.DLL HaviGyujtokbeMasolas
 * — A napi táblák tartalmát havi gyűjtő táblákba másolja.
 * — Tábla neve: prefix + ÉÉVHH (pl. BF2603 = BLOKKFEJ 2026 március)
 *
 * Modern megközelítés: egyetlen összesítő tábla JSON currency breakdown-nal.
 */
@Entity
@Table(name = "monthly_closing_summary", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"branch_id", "year_month"})
}, indexes = {
    @Index(name = "idx_monthly_closing_branch", columnList = "branch_id"),
    @Index(name = "idx_monthly_closing_yearmonth", columnList = "year_month")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MonthlyClosingSummary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Iroda/fiók
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Év-hónap (pl. "2026-03")
     */
    @Column(name = "year_month", nullable = false, length = 7)
    private String yearMonth;

    /**
     * Lezárás időpontja
     */
    @Column(name = "closed_at", nullable = false)
    private LocalDateTime closedAt;

    /**
     * Lezáró dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "closed_by_worker_id", nullable = false)
    private Worker closedBy;

    /**
     * Összes vétel HUF
     */
    @Column(name = "total_buy_huf", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    /**
     * Összes eladás HUF
     */
    @Column(name = "total_sell_huf", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    /**
     * Összes kezelési díj
     */
    @Column(name = "total_handling_fee", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalHandlingFee = BigDecimal.ZERO;

    /**
     * Tranzakciószám
     */
    @Column(name = "transaction_count", nullable = false)
    @Builder.Default
    private Integer transactionCount = 0;

    /**
     * Valutánkénti bontás (JSON formátumban)
     *
     * Példa:
     * [
     *   {"currencyCode":"EUR","buyCount":10,"buyAmount":5000.00,"buyHuf":1900000.00,"sellCount":8,"sellAmount":3000.00,"sellHuf":1170000.00},
     *   {"currencyCode":"USD","buyCount":5,"buyAmount":2000.00,"buyHuf":740000.00,"sellCount":3,"sellAmount":1000.00,"sellHuf":380000.00}
     * ]
     */
    @Column(name = "currency_breakdown", columnDefinition = "TEXT")
    private String currencyBreakdown;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

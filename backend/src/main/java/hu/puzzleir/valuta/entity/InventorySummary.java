package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Központi készlet összesítő nézet (materialized).
 *
 * Legacy mapping: SZERVER — penztarak.dll összesítő nézete,
 * SUMBANKFORGALOM tábla, pk file összesítés
 */
@Entity
@Table(name = "inventory_summary", indexes = {
    @Index(name = "idx_inv_sum_branch", columnList = "branch_id"),
    @Index(name = "idx_inv_sum_currency", columnList = "currency_id"),
    @Index(name = "idx_inv_sum_date", columnList = "summary_date")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_inv_sum_branch_currency_date",
                      columnNames = {"branch_id", "currency_id", "summary_date"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventorySummary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Iroda
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Valutanem
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Aktuális készlet (valutában)
     */
    @Column(name = "current_stock", nullable = false, precision = 18, scale = 4)
    @Builder.Default
    private BigDecimal currentStock = BigDecimal.ZERO;

    /**
     * Napi vételi összeg (HUF)
     */
    @Column(name = "daily_buy_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal dailyBuyTotal = BigDecimal.ZERO;

    /**
     * Napi eladási összeg (HUF)
     */
    @Column(name = "daily_sell_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal dailySellTotal = BigDecimal.ZERO;

    /**
     * Napi kezelési díj összeg (HUF)
     */
    @Column(name = "daily_fee_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal dailyFeeTotal = BigDecimal.ZERO;

    /**
     * Bank kivét összeg (HUF)
     */
    @Column(name = "bank_withdraw_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal bankWithdrawTotal = BigDecimal.ZERO;

    /**
     * Bank befizetés összeg (HUF)
     */
    @Column(name = "bank_deposit_total", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal bankDepositTotal = BigDecimal.ZERO;

    /**
     * Összesítés dátuma
     */
    @Column(name = "summary_date", nullable = false)
    private LocalDate summaryDate;

    /**
     * Utolsó frissítés időpontja
     */
    @Column(name = "last_updated")
    private LocalTime lastUpdated;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

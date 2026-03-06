package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Havi zárás rekord — irodánkénti havi összesítés.
 *
 * Legacy: HAVIZARO tábla — havi gyűjtő
 */
@Entity
@Table(name = "monthly_closing", indexes = {
    @Index(name = "idx_monthly_closing_branch", columnList = "branch_id"),
    @Index(name = "idx_monthly_closing_period", columnList = "year_month"),
    @Index(name = "idx_monthly_closing_company", columnList = "company_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MonthlyClosing {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id")
    private UUID companyId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "year_month", nullable = false, length = 7)
    private String yearMonth;

    @Column(name = "closing_year")
    private Integer closingYear;

    @Column(name = "closing_month")
    private Integer closingMonth;

    @Column(name = "total_buy_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalBuyHuf = BigDecimal.ZERO;

    @Column(name = "total_sell_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalSellHuf = BigDecimal.ZERO;

    @Column(name = "total_profit_huf", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalProfitHuf = BigDecimal.ZERO;

    @Column(name = "total_handling_fees", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalHandlingFees = BigDecimal.ZERO;

    @Column(name = "total_transaction_count")
    @Builder.Default
    private Integer totalTransactionCount = 0;

    @Column(name = "transaction_count")
    @Builder.Default
    private Integer transactionCount = 0;

    @Column(name = "buy_count")
    @Builder.Default
    private Integer buyCount = 0;

    @Column(name = "sell_count")
    @Builder.Default
    private Integer sellCount = 0;

    @Column(name = "reversal_count")
    @Builder.Default
    private Integer reversalCount = 0;

    @Column(name = "status", length = 20)
    @Builder.Default
    private String status = "CLOSED";

    @Column(name = "closed_by_id")
    private Long closedById;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

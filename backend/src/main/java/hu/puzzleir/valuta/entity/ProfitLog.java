package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Profit log: realizált haszon rögzítése ügyféltranzakciónként.
 */
@Entity
@Table(name = "profit_log", indexes = {
    @Index(name = "idx_profit_log_branch", columnList = "branch_id, created_at"),
    @Index(name = "idx_profit_log_company", columnList = "company_id, created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProfitLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "transaction_id")
    private Long transactionId;

    /**
     * Pénztár (branch) azonosítója — UUID
     */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal quantity;

    /**
     * WAC bekerülési ár (Ft/egység)
     */
    @Column(name = "acquisition_cost", nullable = false, precision = 12, scale = 4)
    private BigDecimal acquisitionCost;

    /**
     * Ügyfél felé alkalmazott ár (Ft/egység)
     */
    @Column(name = "sale_price", nullable = false, precision = 12, scale = 4)
    private BigDecimal salePrice;

    /**
     * Realizált haszon: (sale_price - acquisition_cost) × quantity
     */
    @Column(name = "realized_profit", nullable = false, precision = 15, scale = 2)
    private BigDecimal realizedProfit;

    /**
     * Tranzakció típusa: 'SELL' vagy 'BUY'
     */
    @Column(name = "transaction_type", nullable = false, length = 10)
    private String transactionType;

    @Column(name = "compensation_key", length = 120)
    private String compensationKey;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}

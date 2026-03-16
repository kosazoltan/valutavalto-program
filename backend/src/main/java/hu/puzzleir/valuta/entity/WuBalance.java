package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Western Union egyenleg entity.
 *
 * Legacy: WUAFAADATOK tábla — WU készletek irodánként.
 */
@Entity
@Table(name = "wu_balances", uniqueConstraints = {
    @UniqueConstraint(name = "uq_wu_balances_branch_company", columnNames = {"branch_id", "company_id"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WuBalance {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    @Column(name = "usd_balance", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal usdBalance = BigDecimal.ZERO;

    @Column(name = "huf_balance", precision = 18, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal hufBalance = BigDecimal.ZERO;

    @Column(name = "last_receipt_sell", length = 50)
    private String lastReceiptSell;

    @Column(name = "last_receipt_buy", length = 50)
    private String lastReceiptBuy;

    @Column(name = "last_receipt_customer_in", length = 50)
    private String lastReceiptCustomerIn;

    @Column(name = "last_receipt_customer_out", length = 50)
    private String lastReceiptCustomerOut;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

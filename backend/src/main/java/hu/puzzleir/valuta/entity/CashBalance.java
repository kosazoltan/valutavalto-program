package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Kassza egyenleg entity - valutánkénti készlet.
 *
 * Legacy mapping: PENZTAR tábla + PILLALL (pillanat állapot)
 * - Valutánkénti készlet nyilvántartás
 * - Nyitó/záró egyenleg
 */
@Entity
@Table(name = "cash_balance", indexes = {
    @Index(name = "idx_cash_balance_branch", columnList = "branch_id"),
    @Index(name = "idx_cash_balance_currency", columnList = "currency_id")
}, uniqueConstraints = {
    @UniqueConstraint(columnNames = {"branch_id", "currency_id"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CashBalance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /**
     * Iroda/pénztár
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
     * Aktuális egyenleg
     */
    @Column(name = "current_balance", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal currentBalance = BigDecimal.ZERO;

    /**
     * Napi nyitó egyenleg
     */
    @Column(name = "opening_balance", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal openingBalance = BigDecimal.ZERO;

    /**
     * Minimális egyenleg (figyelmeztetéshez)
     */
    @Column(name = "min_balance", precision = 15, scale = 2)
    private BigDecimal minBalance;

    /**
     * Maximális egyenleg
     */
    @Column(name = "max_balance", precision = 15, scale = 2)
    private BigDecimal maxBalance;

    /**
     * Utolsó tranzakció időpontja
     */
    @Column(name = "last_transaction_at")
    private LocalDateTime lastTransactionAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    /**
     * Egyenleg hozzáadás (beérkező valuta)
     */
    public void addBalance(BigDecimal amount) {
        this.currentBalance = this.currentBalance.add(amount);
        this.lastTransactionAt = LocalDateTime.now();
    }

    /**
     * Egyenleg levonás (kimenő valuta)
     */
    public void subtractBalance(BigDecimal amount) {
        if (this.currentBalance.compareTo(amount) >= 0) {
            this.currentBalance = this.currentBalance.subtract(amount);
            this.lastTransactionAt = LocalDateTime.now();
        } else {
            throw new IllegalStateException("Nincs elegendő egyenleg: " + this.currentBalance + " < " + amount);
        }
    }

    /**
     * Napi nyitás - nyitó egyenleg beállítása
     */
    public void setDailyOpening() {
        this.openingBalance = this.currentBalance;
    }

    /**
     * Egyenleg alacsony-e
     */
    public boolean isLowBalance() {
        return minBalance != null && currentBalance.compareTo(minBalance) <= 0;
    }

    /**
     * Egyenleg túl magas-e
     */
    public boolean isHighBalance() {
        return maxBalance != null && currentBalance.compareTo(maxBalance) >= 0;
    }

    /**
     * Napi változás
     */
    public BigDecimal getDailyChange() {
        return currentBalance.subtract(openingBalance);
    }

    /**
     * Egyenleg frissítése (bejövő vagy kimenő)
     * @param amount az összeg (pozitív)
     * @param isIncoming true = beérkező, false = kimenő
     */
    public void updateBalance(BigDecimal amount, boolean isIncoming) {
        if (isIncoming) {
            addBalance(amount);
        } else {
            subtractBalance(amount);
        }
    }
}

package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import jakarta.persistence.*;
import jakarta.persistence.Version;
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
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
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
    @JsonIgnore
    private Company company;

    /**
     * Iroda/pénztár
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    @JsonIgnore
    private Branch branch;

    /**
     * Valutanem
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    @JsonIgnore
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

    @Version
    @Column(columnDefinition = "bigint default 0")
    @Builder.Default
    private Long version = 0L;

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
     * Egyenleg levonás (kimenő valuta).
     *
     * PR #114 fix: korábban IllegalStateException-t dobtunk, ami HTTP 500-ra
     * mapelődött a GlobalExceptionHandler-ben (rossz). Most InsufficientBalanceException
     * (ValidationException leszármazott) -> HTTP 400 Bad Request (helyes business validation).
     */
    public void subtractBalance(BigDecimal amount) {
        if (this.currentBalance.compareTo(amount) >= 0) {
            this.currentBalance = this.currentBalance.subtract(amount);
            this.lastTransactionAt = LocalDateTime.now();
        } else {
            String currencyCode = (this.currency != null ? this.currency.getCode() : "?");
            throw new hu.puzzleir.valuta.exception.InsufficientBalanceException(
                    currencyCode, this.currentBalance, amount);
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

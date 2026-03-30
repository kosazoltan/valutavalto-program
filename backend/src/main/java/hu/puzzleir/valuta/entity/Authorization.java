package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Meghatalmazás entity — egy meghatalmazott képviselő konkrét jogosultsága.
 *
 * Egy representative-nek több Authorization-je lehet (pl. vétel, eladás, konverzió).
 * Lifecycle: PENDING → ACTIVE → (SUSPENDED ↔ ACTIVE) → REVOKED
 */
@Entity
@Table(name = "authorization", indexes = {
    @Index(name = "idx_authorization_representative", columnList = "representative_id"),
    @Index(name = "idx_authorization_status", columnList = "status_did")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Authorization {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "representative_id", nullable = false)
    private UUID representativeId;

    /**
     * Engedélyezett művelet típusa (szótár ID).
     * Pl. BUY, SELL, CONVERSION, TRANSFER, ALL
     */
    @Column(name = "operation_did", nullable = false, length = 50)
    private String operationDid;

    /**
     * Meghatalmazás típusa (szótár ID).
     * Pl. PERMANENT, TEMPORARY, LEGAL_GUARDIAN, POWER_OF_ATTORNEY, COMPANY_DELEGATE
     */
    @Column(name = "authorization_type_did", length = 50)
    private String authorizationTypeDid;

    /**
     * Státusz: PENDING, ACTIVE, SUSPENDED, REVOKED
     */
    @Column(name = "status_did", nullable = false, length = 20)
    @Builder.Default
    private String statusDid = "PENDING";

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    /**
     * Maximum engedélyezett összeg (Ft) egy tranzakcióra.
     */
    @Column(name = "single_transaction_limit", precision = 15, scale = 0)
    private BigDecimal singleTransactionLimit;

    /**
     * Maximum összes tranzakció összege (Ft).
     */
    @Column(name = "max_amount", precision = 15, scale = 0)
    private BigDecimal maxAmount;

    /**
     * Maximum tranzakciók száma.
     */
    @Column(name = "max_transaction_count")
    private Integer maxTransactionCount;

    /**
     * Felhasznált tranzakciók száma.
     */
    @Column(name = "used_transaction_count", nullable = false)
    @Builder.Default
    private Integer usedTransactionCount = 0;

    /**
     * Felhasznált összeg (Ft).
     */
    @Column(name = "used_amount", nullable = false, precision = 15, scale = 0)
    @Builder.Default
    private BigDecimal usedAmount = BigDecimal.ZERO;

    @Column(length = 500)
    private String notes;

    /**
     * Felfüggesztés/visszavonás indoka.
     */
    @Column(name = "status_reason", length = 500)
    private String statusReason;

    @Column(name = "verified_by_worker_id")
    private Long verifiedByWorkerId;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    public boolean isActive() {
        return "ACTIVE".equals(statusDid);
    }

    public boolean isExpired() {
        return expiryDate != null && expiryDate.isBefore(LocalDate.now());
    }

    public boolean isStarted() {
        return startDate != null && !startDate.isAfter(LocalDate.now());
    }

    public boolean canExecuteTransaction(BigDecimal amount) {
        if (!isActive() || isExpired() || !isStarted()) return false;
        if (maxTransactionCount != null && usedTransactionCount >= maxTransactionCount) return false;
        if (singleTransactionLimit != null && amount != null && amount.compareTo(singleTransactionLimit) > 0) return false;
        if (maxAmount != null && amount != null && usedAmount.add(amount).compareTo(maxAmount) > 0) return false;
        return true;
    }

    public void recordUsage(BigDecimal amount) {
        this.usedTransactionCount++;
        if (amount != null) {
            this.usedAmount = this.usedAmount.add(amount);
        }
    }
}

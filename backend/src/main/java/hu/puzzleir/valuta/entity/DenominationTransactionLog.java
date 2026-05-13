package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Címletezési döntés napló — minden tranzakciónál rögzíti, hogy a rendszer
 * milyen stratégia + szabály alapján számolta a kiadandó címleteket, és
 * a pénztáros elfogadta-e vagy módosította.
 *
 * <p>v2.0 specifikáció (07_cimletkezeles.md):
 * "A rendszer rögzíti a kiválasztott címletezési szabályt és naplózza a
 * teljes címletezési folyamatot (`denomination_transaction_log`)."</p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1 (P2-E).</p>
 */
@Entity
@Table(name = "denomination_transaction_log", indexes = {
    @Index(name = "idx_denom_txlog_transaction", columnList = "transaction_id"),
    @Index(name = "idx_denom_txlog_strategy", columnList = "strategy"),
    @Index(name = "idx_denom_txlog_decision", columnList = "decision")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DenominationTransactionLog {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** A tranzakció amihez a címletezés tartozik. */
    @Column(name = "transaction_id", nullable = false)
    private Long transactionId;

    /** Pénztáros (worker_id). */
    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    /** Fiók. */
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /** Alkalmazott stratégia. */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private OptimizationStrategy strategy;

    /** Alkalmazott szabály (ha volt). */
    @Column(name = "rule_id")
    private UUID ruleId;

    /** Tranzakció HUF összege. */
    @Column(name = "huf_amount", precision = 15, scale = 2)
    private BigDecimal hufAmount;

    /** Javasolt címletezés JSON formátumban: `[{denomination: 20000, count: 5}, ...]`. */
    @Column(name = "suggested_breakdown", columnDefinition = "TEXT")
    private String suggestedBreakdownJson;

    /** Elfogadott címletezés JSON formátumban (a tényleges, pénztáros által véglegesített). */
    @Column(name = "accepted_breakdown", columnDefinition = "TEXT")
    private String acceptedBreakdownJson;

    /**
     * Döntés: ACCEPTED (=suggested), MODIFIED (=módosítva), OVERRIDDEN (=teljesen másra),
     * INSUFFICIENT (=készlethiány miatt nem optimális volt).
     */
    @Column(nullable = false, length = 20)
    private String decision;

    /** Készlethiány esetén megjegyzés. */
    @Column(length = 500)
    private String notes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

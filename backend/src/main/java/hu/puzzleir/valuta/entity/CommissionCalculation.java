package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Jutalék számítás entity — havi jutalék elszámolás részletes bontással.
 *
 * Legacy: forrasok/SZERVER/ujdll/jutszamito
 * - JutSzamitas() - penztaros havi forgalma alapjan tier besorolas
 * - Bonusz kuszob: ha eleri a megadott forgalmat, extra jutalek
 */
@Entity
@Table(name = "commission_calculation", uniqueConstraints = {
    @UniqueConstraint(name = "uk_comm_calc_worker_period",
                      columnNames = {"worker_id", "period"})
}, indexes = {
    @Index(name = "idx_comm_calc_branch", columnList = "branch_id"),
    @Index(name = "idx_comm_calc_period", columnList = "period"),
    @Index(name = "idx_comm_calc_status", columnList = "status")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommissionCalculation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    /**
     * Időszak (YYYY-MM formátum)
     */
    @Column(name = "period", nullable = false, length = 7)
    private String period;

    @Enumerated(EnumType.STRING)
    @Column(name = "calculation_type", nullable = false, length = 20)
    @Builder.Default
    private CalculationType calculationType = CalculationType.MONTHLY;

    @Column(name = "total_transactions", nullable = false)
    @Builder.Default
    private Integer totalTransactions = 0;

    @Column(name = "total_volume_huf", nullable = false, precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal totalVolumeHuf = BigDecimal.ZERO;

    @Column(name = "commission_rate", precision = 10, scale = 4)
    @Builder.Default
    private BigDecimal commissionRate = BigDecimal.ZERO;

    @Column(name = "commission_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal commissionAmount = BigDecimal.ZERO;

    @Column(name = "bonus_amount", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal bonusAmount = BigDecimal.ZERO;

    @Column(name = "deductions", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal deductions = BigDecimal.ZERO;

    @Column(name = "net_commission", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal netCommission = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private CommissionStatus status = CommissionStatus.CALCULATED;

    @Column(name = "calculated_at", nullable = false)
    private LocalDateTime calculatedAt;

    @Column(name = "approved_by")
    private Long approvedBy;

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    public enum CalculationType {
        MONTHLY
    }

    public enum CommissionStatus {
        CALCULATED, APPROVED, PAID
    }
}

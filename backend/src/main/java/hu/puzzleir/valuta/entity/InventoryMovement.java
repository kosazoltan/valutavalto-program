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
 * Készlet mozgás entity (bank↔pénztár, irodák közti, korrekció).
 *
 * Legacy mapping: ERTEKTAR — keszup.dll (bank↔pénztár),
 * atadvet.dll (irodák közti), keszedit.dll (korrekció)
 */
@Entity
@Table(name = "inventory_movement", indexes = {
    @Index(name = "idx_inv_mov_from_branch", columnList = "from_branch_id"),
    @Index(name = "idx_inv_mov_to_branch", columnList = "to_branch_id"),
    @Index(name = "idx_inv_mov_currency", columnList = "currency_id"),
    @Index(name = "idx_inv_mov_date", columnList = "movement_date"),
    @Index(name = "idx_inv_mov_status", columnList = "status"),
    @Index(name = "idx_inv_mov_type", columnList = "movement_type")
}, uniqueConstraints = {
    @UniqueConstraint(name = "uk_inv_mov_ref_number", columnNames = {"reference_number"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InventoryMovement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Forrás iroda (null = bank)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "from_branch_id")
    private Branch fromBranch;

    /**
     * Cél iroda (null = bank)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "to_branch_id")
    private Branch toBranch;

    /**
     * Valutanem
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "currency_id", nullable = false)
    private Currency currency;

    /**
     * Összeg (valutában)
     */
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal amount;

    /**
     * HUF érték
     */
    @Column(name = "huf_value", precision = 18, scale = 2)
    private BigDecimal hufValue;

    /**
     * Mozgás típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "movement_type", nullable = false, length = 30)
    private MovementType movementType;

    /**
     * Mozgás státusza
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private MovementStatus status = MovementStatus.PENDING;

    /**
     * Kezdeményező dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "initiated_by_id", nullable = false)
    private Worker initiatedBy;

    /**
     * Jóváhagyó dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by_id")
    private Worker approvedBy;

    /**
     * Fogadó dolgozó
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "received_by_id")
    private Worker receivedBy;

    /**
     * Szállítólevél szám (INV-yyyyMMdd-XXXX formátum)
     */
    @Column(name = "reference_number", nullable = false, unique = true, length = 30)
    private String referenceNumber;

    /**
     * Megjegyzés
     */
    @Column(columnDefinition = "TEXT")
    private String notes;

    /**
     * Mozgás dátuma
     */
    @Column(name = "movement_date", nullable = false)
    private LocalDate movementDate;

    /**
     * Mozgás időpontja
     */
    @Column(name = "movement_time", nullable = false)
    private LocalTime movementTime;

    /**
     * Jóváhagyás időpontja
     */
    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    /**
     * Fogadás időpontja
     */
    @Column(name = "received_at")
    private LocalDateTime receivedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}

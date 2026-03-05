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
 * Jutalék szabály entity — tier-alapú jutalékkulcsok.
 *
 * Legacy: forrasok/SZERVER/ujdll/jutszamito
 * - Tier rendszer: forgalom alapjan lepcsos jutalek %
 * - Bonusz kuszob: extra jutalek ha eleri a megadott forgalmat
 */
@Entity
@Table(name = "commission_rule", indexes = {
    @Index(name = "idx_comm_rule_company", columnList = "company_id"),
    @Index(name = "idx_comm_rule_tier", columnList = "tier")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommissionRule {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "company_id", nullable = false)
    private Integer companyId;

    /**
     * Tier szint (1, 2, 3...)
     */
    @Column(name = "tier", nullable = false)
    private Integer tier;

    /**
     * Minimum forgalom (HUF) ehhez a tier-hez
     */
    @Column(name = "min_volume_huf", nullable = false, precision = 18, scale = 2)
    private BigDecimal minVolumeHuf;

    /**
     * Maximum forgalom (HUF) ehhez a tier-hez (null = korlátlan)
     */
    @Column(name = "max_volume_huf", precision = 18, scale = 2)
    private BigDecimal maxVolumeHuf;

    /**
     * Jutalék százalék
     */
    @Column(name = "rate_percent", nullable = false, precision = 10, scale = 4)
    private BigDecimal ratePercent;

    /**
     * Bónusz küszöb (HUF) — ha a forgalom eléri ezt, extra bónusz jár
     */
    @Column(name = "bonus_threshold", precision = 18, scale = 2)
    private BigDecimal bonusThreshold;

    /**
     * Bónusz százalék
     */
    @Column(name = "bonus_percent", precision = 10, scale = 4)
    @Builder.Default
    private BigDecimal bonusPercent = BigDecimal.ZERO;

    @Column(name = "valid_from", nullable = false)
    private LocalDate validFrom;

    @Column(name = "valid_to")
    private LocalDate validTo;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

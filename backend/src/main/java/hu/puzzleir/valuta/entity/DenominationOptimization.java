package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Címletezési optimalizációs stratégia konfiguráció.
 *
 * <p>v2.0 specifikáció (07_cimletkezeles.md):
 * <ul>
 *   <li>Több stratégia is definiálható párhuzamosan</li>
 *   <li>Egy alapértelmezett (`is_default`) jelölhető rendszerszinten</li>
 *   <li>JSON `priority_order` mező a CUSTOM strategy-hoz</li>
 *   <li>`min_coins` / `min_banknotes` / `min_total_count` extra flag-ek</li>
 * </ul></p>
 *
 * <p>2026-05-13 v2.5.50+ Sprint 1 (P1-A).</p>
 */
@Entity
@Table(name = "denomination_optimization", indexes = {
    @Index(name = "idx_denom_opt_default", columnList = "is_default"),
    @Index(name = "idx_denom_opt_strategy", columnList = "strategy")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DenominationOptimization {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Stratégia név (egyedi a rendszerben). */
    @Column(nullable = false, length = 100, unique = true)
    private String name;

    /** Leírás (opcionális). */
    @Column(length = 500)
    private String description;

    /** Stratégia típusa (GREEDY, DYNAMIC, ...). */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private OptimizationStrategy strategy;

    /**
     * Prioritási sorrend JSON formátumban (CUSTOM strategy esetén):
     * pl. `["20000", "10000", "5000", "1000", "500", "200", "100"]`.
     */
    @Column(name = "priority_order", columnDefinition = "TEXT")
    private String priorityOrderJson;

    /** Érmeminimalizálás bekapcsolva. */
    @Column(name = "min_coins")
    @Builder.Default
    private Boolean minCoins = false;

    /** Bankjegyminimalizálás bekapcsolva. */
    @Column(name = "min_banknotes")
    @Builder.Default
    private Boolean minBanknotes = false;

    /** Összes darabszám minimalizálása. */
    @Column(name = "min_total_count")
    @Builder.Default
    private Boolean minTotalCount = false;

    /** Alapértelmezett-e (egyszerre csak 1 lehet). */
    @Column(name = "is_default", nullable = false)
    @Builder.Default
    private Boolean isDefault = false;

    /** Aktív-e. */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Version
    private Long version;
}

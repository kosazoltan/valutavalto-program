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
 * Címlet entity - bankjegy/érme címletek készletkezelése.
 *
 * Legacy mapping: CIMLET tábla
 * 14-féle címlet: 20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
 * 27 valuta támogatás
 */
@Entity
@Table(name = "denomination", indexes = {
    @Index(name = "idx_denomination_branch", columnList = "branch_id"),
    @Index(name = "idx_denomination_currency", columnList = "currency_id")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Denomination {

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
     * Iroda/pénztár kapcsolat
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
     * Címlet értéke (pl. 10000, 5000, 100, 0.5)
     * Legacy: CIMLETTYPE (14 típus)
     */
    @Column(name = "face_value", nullable = false, precision = 15, scale = 2)
    private BigDecimal faceValue;

    /**
     * Címlet típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "denomination_type", nullable = false, length = 20)
    private DenominationType denominationType;

    /**
     * Aktuális darabszám a kasszában
     */
    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 0;

    /**
     * Minimális készletszint (figyelmeztetéshez)
     */
    @Column(name = "min_quantity")
    @Builder.Default
    private Integer minQuantity = 0;

    /**
     * Maximális készletszint
     */
    @Column(name = "max_quantity")
    private Integer maxQuantity;

    /**
     * Aktív-e a címlet (használható)
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    /**
     * Teljes érték számítása (címlet * darab)
     */
    public BigDecimal getTotalValue() {
        return faceValue.multiply(BigDecimal.valueOf(quantity));
    }

    /**
     * Készlet hozzáadás
     */
    public void addQuantity(int amount) {
        this.quantity += amount;
    }

    /**
     * Készlet levonás
     */
    public void subtractQuantity(int amount) {
        if (this.quantity >= amount) {
            this.quantity -= amount;
        } else {
            throw new IllegalStateException("Nincs elegendő készlet: " + this.quantity + " < " + amount);
        }
    }

    /**
     * Készlet alacsony-e
     */
    public boolean isLowStock() {
        return minQuantity != null && quantity <= minQuantity;
    }
}

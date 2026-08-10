package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pénztárgép címlet egyenleg entity.
 * Pénztárgép szintű címlet darabszám nyilvántartás.
 */
@Entity
@Table(name = "denomination_balance", indexes = {
    @Index(name = "idx_denom_balance_desk", columnList = "cash_desk_id"),
    @Index(name = "idx_denom_balance_denomination", columnList = "denomination_id")
}, uniqueConstraints = {
    // FKH-033 (V378): a kulcsnak tartalmaznia KELL a kategoriat — kategoria nelkul az
    // elso HANDLING_FEE mentes utkozott a mar meglevo EVENING sorral, es a napi zaras
    // varazsloja 500-zal osszeomlott.
    @UniqueConstraint(
        name = "uk_denom_balance_desk_denom_category",
        columnNames = {"cash_desk_id", "denomination_id", "denomination_category"})
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DenominationBalance {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Pénztárgép ID
     */
    @Column(name = "cash_desk_id", nullable = false)
    private UUID cashDeskId;

    /**
     * Címlet referencia
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "denomination_id", nullable = false)
    private Denomination denomination;

    /**
     * Darabszám
     */
    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 0;

    /**
     * Teljes érték (számított: denomination.faceValue * quantity)
     */
    @Column(name = "total_value", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal totalValue = BigDecimal.ZERO;

    /**
     * Címletezési kategória — melyik kasszatípushoz tartozik az egyenleg.
     * Legacy: CIMLET.CIMLETSORSZAM (1=esti, 2=kezelési díj, 3=WU, 4=ÁFA, stb.)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "denomination_category", nullable = false, length = 30)
    @Builder.Default
    private DenominationCategory denominationCategory = DenominationCategory.EVENING;

    /**
     * FK-060: explicit business date set by every supported service writer.
     * There is intentionally no entity lifecycle clock fallback.
     */
    @Column(name = "submission_date", nullable = false)
    private LocalDate submissionDate;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // ============ HELPER METHODS ============

    /**
     * Teljes érték újraszámítása
     */
    public void recalculateTotalValue() {
        if (denomination != null) {
            this.totalValue = denomination.getFaceValue().multiply(BigDecimal.valueOf(quantity));
        }
    }
}

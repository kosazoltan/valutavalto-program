package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Összegyűjtött készlet állapot — valutánkénti snapshot.
 *
 * Legacy: Adatgyűjtő DLL — iroda készletének pillanatképe.
 */
@Entity
@Table(name = "collected_inventory", indexes = {
    @Index(name = "idx_ci_collection", columnList = "data_collection_id"),
    @Index(name = "idx_ci_currency", columnList = "currency_code")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CollectedInventory {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Szülő adatgyűjtés
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "data_collection_id", nullable = false)
    private DataCollection dataCollection;

    /**
     * Valutanem kód
     */
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    /**
     * Készlet összeg (devizában)
     */
    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    /**
     * HUF érték (az aktuális árfolyamon)
     */
    @Column(name = "huf_value", precision = 18, scale = 2)
    @Builder.Default
    private BigDecimal hufValue = BigDecimal.ZERO;

    /**
     * Címlet részletezés (JSON formátum)
     * pl. {"5000": 10, "10000": 5, "20000": 3}
     */
    @Column(name = "denomination_details", columnDefinition = "TEXT")
    private String denominationDetails;
}

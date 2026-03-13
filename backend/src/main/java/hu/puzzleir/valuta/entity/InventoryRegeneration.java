package hu.puzzleir.valuta.entity;

import hu.puzzleir.valuta.entity.Branch;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Készlet regenerálás napló entity.
 *
 * Legacy: regen.dll — készlet újraszámítás tranzakciók alapján.
 */
@Entity
@Table(name = "inventory_regeneration", indexes = {
    @Index(name = "idx_inv_regen_branch", columnList = "branch_id")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryRegeneration {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /** Eredmény adatok (JSON) */
    @Column(name = "result_data", columnDefinition = "TEXT")
    private String resultData;

    @Column(name = "discrepancy_count", nullable = false)
    @Builder.Default
    private Integer discrepancyCount = 0;

    @Column(name = "corrected_count", nullable = false)
    @Builder.Default
    private Integer correctedCount = 0;

    @Column(name = "regenerated_at", nullable = false)
    @Builder.Default
    private LocalDateTime regeneratedAt = LocalDateTime.now();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "regenerated_by")
    private Worker regeneratedBy;
}

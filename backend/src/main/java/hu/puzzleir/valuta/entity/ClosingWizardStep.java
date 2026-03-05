package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

/**
 * Zárási varázsló lépés entity.
 */
@Entity
@Table(name = "closing_wizard_step", indexes = {
    @Index(name = "idx_closing_wizard_step_wizard", columnList = "wizard_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClosingWizardStep {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Varázsló referencia
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "wizard_id", nullable = false)
    private ClosingWizard wizard;

    /**
     * Lépés sorszáma
     */
    @Column(name = "step_number", nullable = false)
    private Integer stepNumber;

    /**
     * Lépés címe
     */
    @Column(name = "step_title", nullable = false, length = 200)
    private String stepTitle;

    /**
     * Lépés leírása
     */
    @Column(name = "step_description", length = 1000)
    private String stepDescription;

    /**
     * Teljesítve van-e
     */
    @Column(nullable = false)
    @Builder.Default
    private Boolean completed = false;

    /**
     * Lehet-e továbblépni
     */
    @Column(name = "can_proceed", nullable = false)
    @Builder.Default
    private Boolean canProceed = true;

    /**
     * Lépés adat (JSON formátumban)
     */
    @Column(name = "step_data", columnDefinition = "TEXT")
    private String stepData;
}

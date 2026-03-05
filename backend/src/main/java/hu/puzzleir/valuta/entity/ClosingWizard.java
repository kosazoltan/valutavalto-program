package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Zárási varázsló entity.
 * Napi/POS/dekádos/havi zárás lépéseit kezeli.
 */
@Entity
@Table(name = "closing_wizard", indexes = {
    @Index(name = "idx_closing_wizard_branch", columnList = "branch_id"),
    @Index(name = "idx_closing_wizard_status", columnList = "wizard_status")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClosingWizard {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Iroda
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /**
     * Pénztárgép ID (opcionális, POS zárásnál)
     */
    @Column(name = "cash_desk_id")
    private UUID cashDeskId;

    /**
     * Zárás dátuma
     */
    @Column(name = "closing_date", nullable = false)
    private LocalDate closingDate;

    /**
     * Zárás típusa
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "closing_type", nullable = false, length = 20)
    private ClosingType closingType;

    /**
     * Aktuális lépés száma
     */
    @Column(name = "current_step", nullable = false)
    @Builder.Default
    private Integer currentStep = 1;

    /**
     * Összes lépés száma
     */
    @Column(name = "total_steps", nullable = false)
    @Builder.Default
    private Integer totalSteps = 5;

    /**
     * Varázsló státusza
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "wizard_status", nullable = false, length = 20)
    @Builder.Default
    private WizardStatus wizardStatus = WizardStatus.IN_PROGRESS;

    /**
     * Indította (pénztáros)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "started_by_worker_id", nullable = false)
    private Worker startedByWorker;

    /**
     * Indítás időpontja
     */
    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    /**
     * Befejező pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "completed_by_worker_id")
    private Worker completedByWorker;

    /**
     * Befejezés időpontja
     */
    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    /**
     * Megjegyzés
     */
    @Column(length = 1000)
    private String notes;

    /**
     * Lépések
     */
    @OneToMany(mappedBy = "wizard", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("stepNumber ASC")
    @Builder.Default
    private List<ClosingWizardStep> steps = new ArrayList<>();
}

package hu.puzzleir.valuta.entity;

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
 * Napi nyitási checklist (legacy: CHECKLST.DLL).
 *
 * 19 tételes ellenőrzőlista, amit a pénztáros minden nap kitölt nyitáskor.
 */
@Entity
@Table(name = "daily_checklist",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_daily_checklist_branch_date",
                columnNames = {"branch_id", "checklist_date", "company_id"}))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyChecklist {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Multi-tenant company szűrés */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;

    /** Fiók (iroda) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    /** Ellenőrzőlista napja */
    @Column(name = "checklist_date", nullable = false)
    private LocalDate checklistDate;

    /** Kitöltő pénztáros */
    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    /** Állapot: OPEN / COMPLETED */
    @Column(nullable = false, length = 20)
    @Builder.Default
    private String status = "OPEN";

    /** Befejezés időpontja */
    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /** A 19 checklist tétel */
    @OneToMany(mappedBy = "checklist", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("itemNumber ASC")
    @Builder.Default
    private List<DailyChecklistItem> items = new ArrayList<>();
}

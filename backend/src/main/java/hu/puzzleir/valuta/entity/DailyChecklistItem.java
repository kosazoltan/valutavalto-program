package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Napi checklist egyedi tétel (1–19).
 *
 * Legacy: CHECKLST.DLL lista elemei.
 */
@Entity
@Table(name = "daily_checklist_item",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_checklist_item_number",
                columnNames = {"checklist_id", "item_number"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DailyChecklistItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Szülő checklist */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "checklist_id", nullable = false)
    private DailyChecklist checklist;

    /** Sorszám (1–19) */
    @Column(name = "item_number", nullable = false)
    private int itemNumber;

    /** Tétel megnevezése */
    @Column(name = "item_title", nullable = false, length = 200)
    private String itemTitle;

    /** Részletes leírás */
    @Column(name = "item_description", length = 500)
    private String itemDescription;

    /** Kipipálva? */
    @Column(nullable = false)
    @Builder.Default
    private boolean checked = false;

    /** Kipipálás időpontja */
    @Column(name = "checked_at")
    private LocalDateTime checkedAt;

    /** Kipipáló dolgozó ID */
    @Column(name = "checked_by_worker_id")
    private Long checkedByWorkerId;

    /** Megjegyzés */
    @Column(length = 500)
    private String notes;
}

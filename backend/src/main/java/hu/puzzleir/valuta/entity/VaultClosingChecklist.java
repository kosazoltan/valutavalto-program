package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Értéktári zárás-előtti ellenőrzőlista entitás.
 *
 * <p>FR-ZARUI-16..26 (b2-zaras-kepernyok-bizonylatok.md)</p>
 * <p>V316 migráció — vault_closing_checklist tábla.</p>
 *
 * <p>Egy rekord = egy pénztár egy napjának checklist állapota.
 * A 9 tétel a spec FR-ZARUI-17..25 szerint. Az auditor mezők
 * FR-ZARUI-26 ellenőrző személy dialógushoz.</p>
 */
@Entity
@Table(
    name = "vault_closing_checklist",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uq_vault_closing_checklist_day",
            columnNames = {"company_id", "branch_id", "closing_date"}
        )
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VaultClosingChecklist {

    @Id
    @GeneratedValue
    private UUID id;

    /** Multi-tenant izoláció — SecurityUtils.getCurrentCompanyId() tölti, soha nem kliens-input. */
    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;

    @Column(name = "closing_date", nullable = false)
    private LocalDate closingDate;

    // === FR-ZARUI-17..25: 9 checklist-tétel ===

    /** FR-ZARUI-17: Minden pénztár készlete feltöltve (címletek, fém euró). */
    @Column(name = "item_1", nullable = false)
    @Builder.Default
    private boolean item1 = false;

    /** FR-ZARUI-18: Esetleges helyettesítéskor kollégának minden infó átadólapon átadva. */
    @Column(name = "item_2", nullable = false)
    @Builder.Default
    private boolean item2 = false;

    /** FR-ZARUI-19: Grafikon kitöltve, kifüggesztve, érintetteknek továbbítva. */
    @Column(name = "item_3", nullable = false)
    @Builder.Default
    private boolean item3 = false;

    /** FR-ZARUI-20: Konkurencia árfolyamainak/készleteinek figyelemmel követése; konkurencia-jelentés megírása (eseti). */
    @Column(name = "item_4", nullable = false)
    @Builder.Default
    private boolean item4 = false;

    /** FR-ZARUI-21: Próbaváltás (eseti); havi beszámoló megírása, lefűzése (eseti). */
    @Column(name = "item_5", nullable = false)
    @Builder.Default
    private boolean item5 = false;

    /** FR-ZARUI-22: Bizonylatok párosítása, lefűzése; Kkts/E-ker/jutalék beszedése-befizetése (eseti). */
    @Column(name = "item_6", nullable = false)
    @Builder.Default
    private boolean item6 = false;

    /** FR-ZARUI-23: TRB tábla kitöltése; egyedi árfolyamos tábla kitöltése+továbbítása (eseti). */
    @Column(name = "item_7", nullable = false)
    @Builder.Default
    private boolean item7 = false;

    /** FR-ZARUI-24: Nagy ügyfélkártyák begyűjtése/összesítése, továbbítása (eseti). */
    @Column(name = "item_8", nullable = false)
    @Builder.Default
    private boolean item8 = false;

    /** FR-ZARUI-25: Hóvégi egyeztetés területekkel (eseti); hóvégi egyeztetés pénztárakkal; SMS küldés (eseti). */
    @Column(name = "item_9", nullable = false)
    @Builder.Default
    private boolean item9 = false;

    // === FR-ZARUI-26: Ellenőrző személy adatai ===

    /** Ellenőrző személy neve — complete() híváskor kötelező. */
    @Column(name = "auditor_name", length = 255)
    private String auditorName;

    /** Ellenőrző személy beosztása — complete() híváskor kötelező. */
    @Column(name = "auditor_role", length = 100)
    private String auditorRole;

    /** Zárást elvégző worker ID. */
    @Column(name = "completed_by_worker_id")
    private Long completedByWorkerId;

    /** Zárás véglegesítésének időpontja. */
    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}

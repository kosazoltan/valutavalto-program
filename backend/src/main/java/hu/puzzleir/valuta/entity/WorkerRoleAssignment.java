package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * Worker ↔ WorkerRoleDefinition kapcsolat.
 * 
 * Egy worker-nek TÖBB operatív szerepköre lehet.
 * isPrimary jelöli az elsődleges (aktív belépési) role-t.
 */
@Entity
@Table(name = "worker_role_assignment", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"worker_id", "role_def_id"})
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkerRoleAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "role_def_id", nullable = false)
    private WorkerRoleDefinition roleDef;

    @Column(name = "is_primary")
    @Builder.Default
    private Boolean isPrimary = false;

    @Column(name = "assigned_at")
    @Builder.Default
    private LocalDateTime assignedAt = LocalDateTime.now();
}

package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.util.UUID;

/**
 * WorkerRoleDef ↔ Permission kapcsolat access_level-lel.
 */
@Entity
@Table(name = "worker_role_permission")
@IdClass(WorkerRolePermission.WorkerRolePermissionId.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WorkerRolePermission {

    @Id
    @Column(name = "role_def_id")
    private Integer roleDefId;

    @Id
    @Column(name = "permission_id")
    private UUID permissionId;

    @Column(name = "access_level", length = 20)
    @Builder.Default
    private String accessLevel = "FULL";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_def_id", insertable = false, updatable = false)
    private WorkerRoleDefinition roleDef;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "permission_id", insertable = false, updatable = false)
    private Permission permission;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkerRolePermissionId implements Serializable {
        private Integer roleDefId;
        private UUID permissionId;
    }
}

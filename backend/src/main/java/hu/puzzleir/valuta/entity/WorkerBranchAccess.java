package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * v2.4.0 (B6 audit fix) — Multi-branch worker access entity.
 *
 * <p>M:N relation between {@link Worker} × {@link Branch}: which branches
 * a worker is authorized to operate on. The composite primary key
 * {@code (worker_id, branch_id)} is mapped via {@link WorkerBranchAccessId}.
 *
 * <p>Defense-in-depth pattern (OWASP A01 multi-tenant):
 * <ul>
 *   <li>Default deny: a worker cannot operate on a branch unless an explicit
 *       {@code worker_branch_access} record exists.</li>
 *   <li>Audit trail: {@code grantedAt} + {@code grantedByWorkerId} —
 *       who granted the access and when.</li>
 *   <li>Backward compat: V173 seeds 1:1 records for all existing workers
 *       (every worker has access to their default {@code branchId}).</li>
 * </ul>
 *
 * <p>Felhasználó-döntés (2026-04-30 06:15 CEST): "C-1: Yes (multi-branch enabled)"
 * — a SetupWizard branchOverride a JWT-be kerül, és a backend ezt a táblát
 * használja a tx-recording ACL-jeként.
 */
@Entity
@Table(name = "worker_branch_access")
@IdClass(WorkerBranchAccess.WorkerBranchAccessId.class)
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkerBranchAccess {

    @Id
    @Column(name = "worker_id", nullable = false)
    private Long workerId;

    @Id
    @Column(name = "branch_id", nullable = false)
    private UUID branchId;

    @CreatedDate
    @Column(name = "granted_at", nullable = false, updatable = false)
    private LocalDateTime grantedAt;

    /**
     * Audit: ki engedélyezte a hozzáférést. NULL ha system-seed (V173) vagy
     * a granter worker törlődött.
     */
    @Column(name = "granted_by_worker_id")
    private Long grantedByWorkerId;

    // === Composite primary key class ===

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WorkerBranchAccessId implements Serializable {
        private static final long serialVersionUID = 1L;

        private Long workerId;
        private UUID branchId;

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof WorkerBranchAccessId that)) return false;
            return Objects.equals(workerId, that.workerId)
                    && Objects.equals(branchId, that.branchId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(workerId, branchId);
        }
    }
}

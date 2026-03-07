package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerRolePermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkerRolePermissionRepository
        extends JpaRepository<WorkerRolePermission, WorkerRolePermission.WorkerRolePermissionId> {

    List<WorkerRolePermission> findByRoleDefId(Integer roleDefId);

    @Query("SELECT wrp FROM WorkerRolePermission wrp " +
           "JOIN FETCH wrp.permission " +
           "WHERE wrp.roleDefId = :roleDefId")
    List<WorkerRolePermission> findByRoleDefIdWithPermission(@Param("roleDefId") Integer roleDefId);

    @Query("SELECT CASE WHEN COUNT(wrp) > 0 THEN true ELSE false END " +
           "FROM WorkerRolePermission wrp " +
           "JOIN wrp.permission p " +
           "WHERE wrp.roleDefId = :roleDefId AND p.code = :permCode")
    boolean existsByRoleDefIdAndPermissionCode(
            @Param("roleDefId") Integer roleDefId,
            @Param("permCode") String permCode);
}

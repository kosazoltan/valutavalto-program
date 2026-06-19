package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerRoleAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WorkerRoleAssignmentRepository extends JpaRepository<WorkerRoleAssignment, Long> {

    List<WorkerRoleAssignment> findByWorkerId(Long workerId);

    /**
     * FK-026: batch-lekérdezés a Dolgozói Törzs lista {@code roleCodes} feltöltéséhez.
     * Egyetlen query több dolgozóra; a {@code roleDef} JOIN FETCH-csel jön, így az EAGER
     * asszociáció sem okoz N+1-et (FR-3).
     */
    @Query("SELECT wra FROM WorkerRoleAssignment wra JOIN FETCH wra.roleDef "
            + "WHERE wra.worker.company.id = :companyId AND wra.worker.id IN :workerIds")
    List<WorkerRoleAssignment> findByCompanyIdAndWorkerIdIn(
            @Param("companyId") UUID companyId,
            @Param("workerIds") Collection<Long> workerIds);

    Optional<WorkerRoleAssignment> findByWorkerIdAndRoleDefCode(Long workerId, String roleCode);

    Optional<WorkerRoleAssignment> findByWorkerIdAndIsPrimaryTrue(Long workerId);

    boolean existsByWorkerIdAndRoleDefCode(Long workerId, String roleCode);

    @Transactional(rollbackFor = Exception.class)
    void deleteByWorkerIdAndRoleDefCode(Long workerId, String roleCode);

    long countByWorkerId(Long workerId);
}

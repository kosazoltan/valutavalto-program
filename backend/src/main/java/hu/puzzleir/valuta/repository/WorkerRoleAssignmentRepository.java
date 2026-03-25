package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerRoleAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Repository
public interface WorkerRoleAssignmentRepository extends JpaRepository<WorkerRoleAssignment, Long> {

    List<WorkerRoleAssignment> findByWorkerId(Long workerId);

    Optional<WorkerRoleAssignment> findByWorkerIdAndRoleDefCode(Long workerId, String roleCode);

    Optional<WorkerRoleAssignment> findByWorkerIdAndIsPrimaryTrue(Long workerId);

    boolean existsByWorkerIdAndRoleDefCode(Long workerId, String roleCode);

    @Transactional(rollbackFor = Exception.class)
    void deleteByWorkerIdAndRoleDefCode(Long workerId, String roleCode);

    long countByWorkerId(Long workerId);
}

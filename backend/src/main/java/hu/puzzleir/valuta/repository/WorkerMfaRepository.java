package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerMfa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface WorkerMfaRepository extends JpaRepository<WorkerMfa, UUID> {

    Optional<WorkerMfa> findByWorkerId(Long workerId);

    boolean existsByWorkerIdAndIsEnabledTrue(Long workerId);
}

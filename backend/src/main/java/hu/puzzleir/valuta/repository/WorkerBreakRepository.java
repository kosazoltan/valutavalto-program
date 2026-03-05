package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerBreak;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WorkerBreakRepository extends JpaRepository<WorkerBreak, UUID> {

    @Query("SELECT b FROM WorkerBreak b WHERE b.worker.id = :workerId " +
           "AND b.breakEnd IS NULL ORDER BY b.breakStart DESC")
    Optional<WorkerBreak> findActiveBreak(@Param("workerId") Long workerId);

    @Query("SELECT b FROM WorkerBreak b WHERE b.worker.id = :workerId " +
           "ORDER BY b.breakStart DESC")
    List<WorkerBreak> findByWorkerId(@Param("workerId") Long workerId);
}

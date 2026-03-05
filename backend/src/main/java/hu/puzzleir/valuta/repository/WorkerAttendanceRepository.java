package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerAttendance;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.UUID;

@Repository
public interface WorkerAttendanceRepository extends JpaRepository<WorkerAttendance, UUID> {

    @Query("SELECT a FROM WorkerAttendance a WHERE a.worker.id = :workerId " +
           "ORDER BY a.loginAt DESC")
    Page<WorkerAttendance> findByWorkerId(
            @Param("workerId") Long workerId,
            Pageable pageable);

    @Query("SELECT a FROM WorkerAttendance a WHERE a.worker.id = :workerId " +
           "AND a.loginAt >= :from AND a.loginAt <= :to " +
           "ORDER BY a.loginAt DESC")
    Page<WorkerAttendance> findByWorkerIdAndDateRange(
            @Param("workerId") Long workerId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);
}

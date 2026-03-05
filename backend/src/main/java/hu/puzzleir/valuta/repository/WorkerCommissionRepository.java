package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerCommission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface WorkerCommissionRepository extends JpaRepository<WorkerCommission, UUID> {

    @Query("SELECT wc FROM WorkerCommission wc WHERE " +
           "(:workerId IS NULL OR wc.workerId = :workerId) " +
           "AND (:periodStart IS NULL OR wc.periodStart >= :periodStart) " +
           "AND (:periodEnd IS NULL OR wc.periodEnd <= :periodEnd) " +
           "ORDER BY wc.periodStart DESC")
    List<WorkerCommission> findWithFilters(
            @Param("workerId") Long workerId,
            @Param("periodStart") LocalDate periodStart,
            @Param("periodEnd") LocalDate periodEnd);

    @Query("SELECT wc FROM WorkerCommission wc WHERE " +
           "wc.branchId = :branchId " +
           "AND wc.periodStart = :periodStart " +
           "AND wc.periodEnd = :periodEnd " +
           "ORDER BY wc.workerId")
    List<WorkerCommission> findByBranchAndPeriod(
            @Param("branchId") UUID branchId,
            @Param("periodStart") LocalDate periodStart,
            @Param("periodEnd") LocalDate periodEnd);
}

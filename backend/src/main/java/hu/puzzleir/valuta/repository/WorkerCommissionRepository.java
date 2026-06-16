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

    /**
     * Multi-tenant IDOR (NEW-3): a jutalék a branch-en keresztül company-scoped.
     * A branchId tulajdonos cégét join-feltétellel szűrjük, így workerId-enumerálással
     * sem szivárog ki más cég payroll-PII adata. A Branch entity company.id-ja az
     * izolációs határ.
     */
    @Query("SELECT wc FROM WorkerCommission wc " +
           "WHERE wc.branchId IN (SELECT b.id FROM Branch b WHERE b.company.id = :companyId) " +
           "AND (:workerId IS NULL OR wc.workerId = :workerId) " +
           "AND (:periodStart IS NULL OR wc.periodStart >= :periodStart) " +
           "AND (:periodEnd IS NULL OR wc.periodEnd <= :periodEnd) " +
           "ORDER BY wc.periodStart DESC")
    List<WorkerCommission> findWithFilters(
            @Param("companyId") UUID companyId,
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

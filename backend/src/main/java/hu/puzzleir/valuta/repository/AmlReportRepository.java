package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.AmlReport;
import hu.puzzleir.valuta.entity.AmlReportStatus;
import hu.puzzleir.valuta.entity.AmlReportType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AmlReportRepository extends JpaRepository<AmlReport, UUID> {

    List<AmlReport> findByCompanyIdAndStatus(UUID companyId, AmlReportStatus status);

    List<AmlReport> findByCompanyIdAndCustomerId(UUID companyId, String customerId);

    @Query("SELECT r FROM AmlReport r WHERE r.company.id = :companyId " +
           "AND r.status IN ('DRAFT', 'SUBMITTED') " +
           "ORDER BY r.createdAt DESC")
    List<AmlReport> findPendingByCompanyId(@Param("companyId") UUID companyId);

    @Query("SELECT r FROM AmlReport r WHERE r.company.id = :companyId " +
           "AND r.createdAt BETWEEN :from AND :to " +
           "ORDER BY r.createdAt DESC")
    List<AmlReport> findByCompanyIdAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    @Query("SELECT COUNT(r) FROM AmlReport r WHERE r.company.id = :companyId " +
           "AND r.createdAt BETWEEN :from AND :to " +
           "AND r.reportType = :type")
    long countByCompanyIdAndDateRangeAndType(
        @Param("companyId") UUID companyId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to,
        @Param("type") AmlReportType type
    );

    /**
     * DRAFT bejelentések, amelyek határideje lejárt (2 munkanap).
     * 2017. LIII. tv. 33.§
     */
    @Query("SELECT r FROM AmlReport r WHERE r.status = 'DRAFT' " +
           "AND r.deadlineAt IS NOT NULL AND r.deadlineAt < :now " +
           "ORDER BY r.deadlineAt ASC")
    List<AmlReport> findOverdueReports(@Param("now") LocalDateTime now);

    /**
     * Cégszintű overdue bejelentések.
     */
    @Query("SELECT r FROM AmlReport r WHERE r.company.id = :companyId " +
           "AND r.status IN ('DRAFT', 'OVERDUE') " +
           "AND r.deadlineAt IS NOT NULL AND r.deadlineAt < :now " +
           "ORDER BY r.deadlineAt ASC")
    List<AmlReport> findOverdueByCompanyId(
        @Param("companyId") UUID companyId,
        @Param("now") LocalDateTime now
    );
}

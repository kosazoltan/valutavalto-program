package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MnbReport;
import hu.puzzleir.valuta.entity.MnbReportStatus;
import hu.puzzleir.valuta.entity.MnbReportType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * MNB riport repository.
 */
@Repository
public interface MnbReportRepository extends JpaRepository<MnbReport, UUID> {

    /**
     * Riport keresése típus és dátum alapján
     */
    Optional<MnbReport> findByReportTypeAndReportDateAndBranchId(
        MnbReportType reportType, LocalDate reportDate, UUID branchId);

    /**
     * Riportok státusz alapján
     */
    List<MnbReport> findByStatus(MnbReportStatus status);

    /**
     * Riportok iroda és időszak szerint
     */
    List<MnbReport> findByBranchIdAndReportDateBetween(UUID branchId, LocalDate from, LocalDate to);

    /**
     * Riportok szűrése lapozással
     */
    @Query("SELECT r FROM MnbReport r " +
           "WHERE (:branchId IS NULL OR r.branch.id = :branchId) " +
           "AND (:reportType IS NULL OR r.reportType = :reportType) " +
           "AND (:status IS NULL OR r.status = :status) " +
           "AND (:dateFrom IS NULL OR r.reportDate >= :dateFrom) " +
           "AND (:dateTo IS NULL OR r.reportDate <= :dateTo) " +
           "ORDER BY r.reportDate DESC")
    Page<MnbReport> findWithFilters(
        @Param("branchId") UUID branchId,
        @Param("reportType") MnbReportType reportType,
        @Param("status") MnbReportStatus status,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo,
        Pageable pageable
    );
}

package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DariusDailyReport;
import hu.puzzleir.valuta.entity.DariusReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DariusDailyReportRepository extends JpaRepository<DariusDailyReport, UUID> {

    Optional<DariusDailyReport> findByIdAndCompanyId(UUID id, UUID companyId);

    Optional<DariusDailyReport> findByCompanyIdAndReportDate(UUID companyId, LocalDate reportDate);

    List<DariusDailyReport> findByCompanyIdAndReportDateBetweenOrderByReportDateDesc(
        UUID companyId, LocalDate startDate, LocalDate endDate);

    List<DariusDailyReport> findByCompanyIdAndStatusOrderByReportDateDesc(
        UUID companyId, DariusReportStatus status);

    /**
     * Retry-re váró jelentések (FAILED státusz, retry limit nem elérve, idő lejárt).
     */
    @Query("SELECT d FROM DariusDailyReport d " +
           "WHERE d.companyId = :companyId " +
           "AND d.status = 'FAILED' " +
           "AND d.retryCount < d.maxRetries " +
           "AND (d.nextRetryAt IS NULL OR d.nextRetryAt <= :now) " +
           "ORDER BY d.reportDate ASC")
    List<DariusDailyReport> findRetryable(
        @Param("companyId") UUID companyId,
        @Param("now") LocalDateTime now);

    /**
     * Hiányzó napok: nincs jelentés a megadott időszakban.
     */
    @Query("SELECT d.reportDate FROM DariusDailyReport d " +
           "WHERE d.companyId = :companyId " +
           "AND d.reportDate BETWEEN :startDate AND :endDate")
    List<LocalDate> findExistingDates(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate);

    /**
     * Havi összesítő: adott hónapban beküldött jelentések.
     */
    List<DariusDailyReport> findByCompanyIdAndStatusAndReportDateBetween(
        UUID companyId, DariusReportStatus status, LocalDate startDate, LocalDate endDate);
}

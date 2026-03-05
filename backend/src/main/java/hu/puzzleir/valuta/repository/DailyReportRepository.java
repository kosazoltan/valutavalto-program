package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyReportRepository extends JpaRepository<DailyReport, Long> {

    Optional<DailyReport> findByBranchIdAndReportDate(UUID branchId, LocalDate reportDate);

    @Query("SELECT r FROM DailyReport r " +
           "WHERE r.reportDate = :date " +
           "ORDER BY r.branch.name")
    List<DailyReport> findAllByReportDate(@Param("date") LocalDate date);

    @Query("SELECT r FROM DailyReport r " +
           "WHERE r.reportDate = :date AND r.submitted = true " +
           "ORDER BY r.branch.name")
    List<DailyReport> findSubmittedByDate(@Param("date") LocalDate date);

    @Query("SELECT r FROM DailyReport r " +
           "WHERE r.reportDate = :date AND r.submitted = false " +
           "ORDER BY r.branch.name")
    List<DailyReport> findUnsubmittedByDate(@Param("date") LocalDate date);
}

package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.InventorySummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InventorySummaryRepository extends JpaRepository<InventorySummary, Long> {

    @Query("SELECT s FROM InventorySummary s " +
           "WHERE s.branch.id = :branchId AND s.summaryDate = :date " +
           "ORDER BY s.currency.displayOrder")
    List<InventorySummary> findByBranchIdAndSummaryDate(
            @Param("branchId") UUID branchId,
            @Param("date") LocalDate date);

    Optional<InventorySummary> findByBranchIdAndCurrencyIdAndSummaryDate(
            UUID branchId, Long currencyId, LocalDate summaryDate);

    @Query("SELECT s FROM InventorySummary s " +
           "WHERE s.summaryDate = :date " +
           "ORDER BY s.branch.name, s.currency.displayOrder")
    List<InventorySummary> findAllBySummaryDate(@Param("date") LocalDate date);
}

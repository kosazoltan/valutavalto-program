package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.MonthlyClosingSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * MonthlyClosingSummary repository.
 *
 * Legacy: NAPZAR.DLL havi gyűjtő táblák keresése.
 */
@Repository
public interface MonthlyClosingSummaryRepository extends JpaRepository<MonthlyClosingSummary, Long> {

    /**
     * Adott branch + hónap lekérdezése.
     */
    Optional<MonthlyClosingSummary> findByBranchIdAndYearMonth(UUID branchId, String yearMonth);

    /**
     * Branch összes lezárt hónapja, fordított sorrendben.
     */
    @Query("SELECT m FROM MonthlyClosingSummary m " +
           "WHERE m.branch.id = :branchId " +
           "ORDER BY m.yearMonth DESC")
    List<MonthlyClosingSummary> findAllByBranchId(@Param("branchId") UUID branchId);

    /**
     * Létezik-e már a havi zárás.
     */
    boolean existsByBranchIdAndYearMonth(UUID branchId, String yearMonth);
}

package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.HandlingFeeDecadeReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface HandlingFeeDecadeReportRepository extends JpaRepository<HandlingFeeDecadeReport, UUID> {

    Optional<HandlingFeeDecadeReport> findByBranchIdAndYearAndDecade(UUID branchId, int year, int decade);

    Page<HandlingFeeDecadeReport> findByBranchIdAndYear(UUID branchId, int year, Pageable pageable);

    /**
     * Előző dekád záró egyenlegének lekérdezése (nyitó egyenleg számításhoz).
     * Legacy: NAPIKEZELESIDIJ.ZARO — az előző dekád záró = következő nyitó.
     */
    @Query("SELECT h.closingBalance FROM HandlingFeeDecadeReport h " +
           "WHERE h.branch.id = :branchId AND (h.year * 100 + h.decade) < (:year * 100 + :decade) " +
           "ORDER BY h.year DESC, h.decade DESC LIMIT 1")
    Optional<java.math.BigDecimal> findPreviousClosingBalance(
        @Param("branchId") UUID branchId,
        @Param("year") int year,
        @Param("decade") int decade);
}

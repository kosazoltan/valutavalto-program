package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CompetitorRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface CompetitorRateRepository extends JpaRepository<CompetitorRate, UUID> {

    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.rateDate = :date " +
           "ORDER BY cr.competitor.name, cr.currency.displayOrder")
    List<CompetitorRate> findByRateDateWithDetails(@Param("date") LocalDate date);

    @Query("SELECT cr FROM CompetitorRate cr " +
           "JOIN FETCH cr.competitor " +
           "JOIN FETCH cr.currency " +
           "WHERE cr.rateDate = (SELECT MAX(cr2.rateDate) FROM CompetitorRate cr2) " +
           "ORDER BY cr.competitor.name, cr.currency.displayOrder")
    List<CompetitorRate> findLatestRatesWithDetails();
}

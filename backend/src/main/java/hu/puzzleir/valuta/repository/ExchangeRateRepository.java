package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ExchangeRate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * ExchangeRate repository.
 */
@Repository
public interface ExchangeRateRepository extends JpaRepository<ExchangeRate, Long> {

    /**
     * Aktuális árfolyam egy valutához (legutolsó aktív)
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.active = true " +
           "AND (er.branch.id = :branchId OR er.branch IS NULL) " +
           "ORDER BY er.validDate DESC, er.validTime DESC")
    List<ExchangeRate> findCurrentRate(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("branchId") UUID branchId
    );

    /**
     * Összes aktív árfolyam egy céghez
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.company.id = :companyId " +
           "AND er.active = true " +
           "AND er.validDate = :date " +
           "ORDER BY er.currency.displayOrder")
    List<ExchangeRate> findActiveRatesByDate(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date
    );

    /**
     * Árfolyam adott időpontra
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.validDate = :date " +
           "AND er.validTime <= :time " +
           "ORDER BY er.validTime DESC")
    List<ExchangeRate> findRateAtTime(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("date") LocalDate date,
        @Param("time") LocalTime time
    );

    /**
     * Árfolyam történet egy valutához
     */
    @Query("SELECT er FROM ExchangeRate er " +
           "WHERE er.company.id = :companyId " +
           "AND er.currency.id = :currencyId " +
           "AND er.validDate BETWEEN :startDate AND :endDate " +
           "ORDER BY er.validDate DESC, er.validTime DESC")
    List<ExchangeRate> findRateHistory(
        @Param("companyId") UUID companyId,
        @Param("currencyId") Long currencyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Legutolsó árfolyam egy valutához
     */
    default Optional<ExchangeRate> findLatestRate(UUID companyId, Long currencyId, UUID branchId) {
        List<ExchangeRate> rates = findCurrentRate(companyId, currencyId, branchId);
        return rates.isEmpty() ? Optional.empty() : Optional.of(rates.get(0));
    }
}

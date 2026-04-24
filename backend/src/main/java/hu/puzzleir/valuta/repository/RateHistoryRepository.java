package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.RateHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RateHistoryRepository extends JpaRepository<RateHistory, Long> {

    /**
     * Árfolyam történet valuta + dátumtartomány alapján
     */
    @Query("SELECT rh FROM RateHistory rh " +
           "WHERE rh.currencyCode = :currency " +
           "AND rh.companyId = :companyId " +
           "AND rh.effectiveFrom >= :fromDate " +
           "AND rh.effectiveFrom <= :toDate " +
           "ORDER BY rh.effectiveFrom DESC")
    List<RateHistory> findByCurrencyAndDateRange(
            @Param("companyId") UUID companyId,
            @Param("currency") String currency,
            @Param("fromDate") LocalDateTime fromDate,
            @Param("toDate") LocalDateTime toDate);

    /**
     * Legutóbbi árfolyam egy valutához
     */
    @Query("SELECT rh FROM RateHistory rh " +
           "WHERE rh.currencyCode = :currency " +
           "AND rh.companyId = :companyId " +
           "ORDER BY rh.effectiveFrom DESC " +
           "LIMIT 1")
    Optional<RateHistory> findLatestByCurrency(
            @Param("companyId") UUID companyId,
            @Param("currency") String currency);

    /**
     * Adott pillanatban érvényes árfolyam
     */
    @Query("SELECT rh FROM RateHistory rh " +
           "WHERE rh.currencyCode = :currency " +
           "AND rh.companyId = :companyId " +
           "AND rh.effectiveFrom <= :dateTime " +
           "AND (rh.effectiveTo IS NULL OR rh.effectiveTo > :dateTime) " +
           "ORDER BY rh.effectiveFrom DESC " +
           "LIMIT 1")
    Optional<RateHistory> findRateAtDate(
            @Param("companyId") UUID companyId,
            @Param("currency") String currency,
            @Param("dateTime") LocalDateTime dateTime);

    /**
     * Fix 2026-04-24 (Issue #184): osszes currency history datum-tartomanyban.
     * Frontend RateHistoryPage a teljes listat keri, nem valuta-szerint.
     */
    @Query("SELECT rh FROM RateHistory rh " +
           "WHERE rh.companyId = :companyId " +
           "AND rh.effectiveFrom >= :fromDate " +
           "AND rh.effectiveFrom <= :toDate " +
           "ORDER BY rh.effectiveFrom DESC")
    List<RateHistory> findByDateRange(
            @Param("companyId") UUID companyId,
            @Param("fromDate") LocalDateTime fromDate,
            @Param("toDate") LocalDateTime toDate);
}

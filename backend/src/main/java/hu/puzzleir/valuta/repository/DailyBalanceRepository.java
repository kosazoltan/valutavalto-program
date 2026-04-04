package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyBalanceRepository extends JpaRepository<DailyBalance, Long> {

    /**
     * Iroda + dátum + valuta szerint keresés
     */
    Optional<DailyBalance> findByBranchIdAndBalanceDateAndCurrencyCode(
        UUID branchId, LocalDate balanceDate, String currencyCode);

    /**
     * Egy nap összes napi mérlege (iroda szerint)
     */
    List<DailyBalance> findByBranchIdAndBalanceDate(UUID branchId, LocalDate balanceDate);

    /**
     * Egy hónap összes napi mérlege
     */
    @Query("SELECT db FROM DailyBalance db WHERE db.branchId = :branchId " +
           "AND YEAR(db.balanceDate) = :year AND MONTH(db.balanceDate) = :month " +
           "ORDER BY db.balanceDate, db.currencyCode")
    List<DailyBalance> findByBranchAndMonth(
        @Param("branchId") UUID branchId,
        @Param("year") int year,
        @Param("month") int month);

    /**
     * Lezáratlan mérlegek keresése
     */
    @Query("SELECT db FROM DailyBalance db WHERE db.branchId = :branchId AND db.isClosed = false " +
           "ORDER BY db.balanceDate DESC")
    List<DailyBalance> findUnclosedByBranch(@Param("branchId") UUID branchId);

    /**
     * Előző nap záró egyenlege (nyitó számításhoz)
     */
    @Query("SELECT db.closingBalance FROM DailyBalance db WHERE db.branchId = :branchId " +
           "AND db.currencyCode = :currencyCode AND db.balanceDate = :date")
    Optional<java.math.BigDecimal> findClosingBalance(
        @Param("branchId") UUID branchId,
        @Param("currencyCode") String currencyCode,
        @Param("date") LocalDate date);

    /**
     * Hónap végi záró készlet (következő hó nyitójához)
     */
    @Query("SELECT db FROM DailyBalance db WHERE db.branchId = :branchId " +
           "AND db.currencyCode = :currencyCode " +
           "AND YEAR(db.balanceDate) = :year AND MONTH(db.balanceDate) = :month " +
           "ORDER BY db.balanceDate DESC")
    List<DailyBalance> findMonthlyClosingBalance(
        @Param("branchId") UUID branchId,
        @Param("currencyCode") String currencyCode,
        @Param("year") int year,
        @Param("month") int month);

    /**
     * Lezárt napok dátumainak lekérdezése egy időszakban (dekádjelentés teljességi ellenőrzéshez).
     */
    @Query("SELECT DISTINCT db.balanceDate FROM DailyBalance db WHERE db.branchId = :branchId " +
           "AND db.balanceDate BETWEEN :from AND :to ORDER BY db.balanceDate")
    List<LocalDate> findClosedDates(
        @Param("branchId") UUID branchId,
        @Param("from") LocalDate from,
        @Param("to") LocalDate to);

    /**
     * MNB gyűjtő batch lekérdezés: több iroda napi készletadatai egy napra.
     * S1-01: Egyetlen query az N+1 probléma elkerüléséhez.
     */
    @Query("SELECT db FROM DailyBalance db WHERE db.branchId IN :branchIds " +
           "AND db.balanceDate = :date ORDER BY db.branchId, db.currencyCode")
    List<DailyBalance> findByBranchIdsAndDate(
        @Param("branchIds") List<UUID> branchIds,
        @Param("date") LocalDate date);

    /**
     * MNB gyűjtő batch lekérdezés: több iroda készletadatai egy időszakra.
     * S1-01: Havi aggregáláshoz.
     */
    @Query("SELECT db FROM DailyBalance db WHERE db.branchId IN :branchIds " +
           "AND db.balanceDate BETWEEN :from AND :to " +
           "ORDER BY db.branchId, db.balanceDate, db.currencyCode")
    List<DailyBalance> findByBranchIdsAndDateRange(
        @Param("branchIds") List<UUID> branchIds,
        @Param("from") LocalDate from,
        @Param("to") LocalDate to);
}

package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DenominationBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Pénztárgép címlet egyenleg repository.
 */
@Repository
public interface DenominationBalanceRepository extends JpaRepository<DenominationBalance, UUID> {

    /**
     * Pénztárgép összes címlet egyenlege
     */
    List<DenominationBalance> findByCashDeskId(UUID cashDeskId);

    /**
     * Pénztárgép adott valutájú címletei
     */
    @Query("SELECT db FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :cashDeskId " +
           "AND db.denomination.currency.id = :currencyId")
    List<DenominationBalance> findByCashDeskIdAndCurrencyId(
        @Param("cashDeskId") UUID cashDeskId,
        @Param("currencyId") Long currencyId
    );

    /**
     * Egyedi rekord: pénztárgép + címlet
     */
    Optional<DenominationBalance> findByCashDeskIdAndDenominationId(UUID cashDeskId, Long denominationId);

    /**
     * Pénztárgép adott valutájú címletek teljes értékének összege
     */
    @Query("SELECT COALESCE(SUM(db.totalValue), 0) FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :cashDeskId " +
           "AND db.denomination.currency.id = :currencyId")
    BigDecimal sumTotalValueByCashDeskIdAndCurrencyId(
        @Param("cashDeskId") UUID cashDeskId,
        @Param("currencyId") Long currencyId
    );

    // ============ NAPZARAS QUERY-K ============

    /**
     * Van-e cimletez es az adott irodahoz es datumhoz?
     */
    @Query("SELECT COUNT(db) > 0 FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.updatedAt >= CAST(:date AS timestamp)")
    boolean existsByBranchIdAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date
    );

    /**
     * Van-e adott tipusu cimletez es?
     */
    @Query("SELECT COUNT(db) > 0 FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.updatedAt >= CAST(:date AS timestamp)")
    boolean existsByBranchIdAndDateAndType(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("type") String type
    );

    /**
     * Cimletezett osszeg a napzarashoz.
     */
    @Query("SELECT COALESCE(SUM(db.totalValue), 0) FROM DenominationBalance db " +
           "WHERE db.cashDeskId = :branchId " +
           "AND db.updatedAt >= CAST(:date AS timestamp)")
    BigDecimal sumDenominatedAmount(
        @Param("branchId") UUID branchId,
        @Param("date") java.time.LocalDate date,
        @Param("type") String type
    );
}

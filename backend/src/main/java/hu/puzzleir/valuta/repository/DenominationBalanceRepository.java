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
}

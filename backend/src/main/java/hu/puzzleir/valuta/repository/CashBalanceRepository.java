package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashBalance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * CashBalance repository.
 */
@Repository
public interface CashBalanceRepository extends JpaRepository<CashBalance, Long> {

    /**
     * Egyenleg keresése fiók és valuta alapján
     */
    Optional<CashBalance> findByBranchIdAndCurrencyId(UUID branchId, Long currencyId);

    /**
     * Összes egyenleg egy fiókhoz
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId " +
           "ORDER BY cb.currency.displayOrder")
    List<CashBalance> findByBranchId(@Param("branchId") UUID branchId);

    /**
     * Összes egyenleg egy céghez
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.company.id = :companyId " +
           "ORDER BY cb.branch.name, cb.currency.displayOrder")
    List<CashBalance> findByCompanyId(@Param("companyId") UUID companyId);

    /**
     * Alacsony készletű egyenlegek
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.company.id = :companyId " +
           "AND cb.currentBalance <= cb.minBalance " +
           "AND cb.minBalance IS NOT NULL")
    List<CashBalance> findLowBalances(@Param("companyId") UUID companyId);

    /**
     * Magas készletű egyenlegek
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.company.id = :companyId " +
           "AND cb.currentBalance >= cb.maxBalance " +
           "AND cb.maxBalance IS NOT NULL")
    List<CashBalance> findHighBalances(@Param("companyId") UUID companyId);
}

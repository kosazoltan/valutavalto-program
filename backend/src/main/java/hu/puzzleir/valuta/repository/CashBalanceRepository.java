package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashBalance;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
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
     * Egyenleg keresése fiók és valuta alapján — JOIN FETCH a lazy branch/currency proxy ellen.
     *
     * 2026-05-27 (live-API teszt #865): a GET /cash-balances/code/{code} és /currency/{id}
     * a derived findByBranchIdAndCurrencyId-t használta (lazy branch+currency), majd a
     * controller a session lezárása UTÁN (OSIV=false) hívta a CashBalanceMapper.toDto-t →
     * LazyInitializationException (Branch proxy, no session) → HTTP 500. A lista-végpontok
     * (findByBranchId/findByCompanyId) már JOIN FETCH-elnek; ez a single-balance párjuk.
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.branch.id = :branchId AND cb.currency.id = :currencyId")
    Optional<CashBalance> findByBranchIdAndCurrencyIdWithDetails(
            @Param("branchId") UUID branchId, @Param("currencyId") Long currencyId);

    /**
     * Egyenleg keresése PESSIMISTIC_WRITE lockkal (race condition védelem).
     * CRITICAL FIX: Párhuzamos készletmódosítás megakadályozása.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT cb FROM CashBalance cb WHERE cb.branch.id = :branchId AND cb.currency.id = :currencyId")
    Optional<CashBalance> findByBranchIdAndCurrencyIdForUpdate(
            @Param("branchId") UUID branchId, @Param("currencyId") Long currencyId);

    /**
     * Összes egyenleg egy fiókhoz (JOIN FETCH a lazy proxy hiba elkerüléséhez)
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.branch.id = :branchId " +
           "ORDER BY cb.currency.displayOrder")
    List<CashBalance> findByBranchId(@Param("branchId") UUID branchId);

    /**
     * Issue #110 / Sourcery feedback: létezik-e cash_balance erre a branch-re?
     *
     * Könnyebb query — csak COUNT, nem lekéri az összes rekordot.
     * Használat: SessionOpenService lazy-init check.
     */
    @Query("SELECT CASE WHEN COUNT(cb) > 0 THEN true ELSE false END FROM CashBalance cb WHERE cb.branch.id = :branchId")
    boolean existsByBranchId(@Param("branchId") UUID branchId);

    /**
     * Összes egyenleg egy céghez (JOIN FETCH a lazy proxy hiba elkerüléséhez)
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.company.id = :companyId " +
           "ORDER BY cb.branch.name, cb.currency.displayOrder")
    List<CashBalance> findByCompanyId(@Param("companyId") UUID companyId);

    /**
     * FK-038 (2026-06-21): cég-szintű kassza-egyenlegek az ÉRTÉKTÁR (is_vault=TRUE) branch-ek
     * KIZÁRÁSÁVAL — a {@link #findByCompanyId(UUID)} defenzív, pénztár-only párja.
     *
     * INVARIÁNS (V334/FK-036): egy értéktár (is_vault=TRUE) branch-nek SOHA nem szabad
     * cash_balance (pénztár-kassza) sora legyen; az értéktár-készlet a currency_stock /
     * vault_territory úton él. A V247-bug korábban hibásan a BR020 értéktárba szivárogtatott
     * pénztár-egyenleget, amit a V334 fizikailag takarított. Ez a query DEFENSE-IN-DEPTH:
     * ha a jövőben ismét „beszivárogna" egy értéktár cash_balance sor, a cég-szintű pénztári
     * kassza-nézet (CashBalanceService.getCompanyBalances → /cash-balances/company:
     * Dashboard „TOP Irodák" + „Zárási állapot (ma)" widget + StockMatrix) akkor se listázza.
     *
     * A predikátum a {@link BranchRepository#findRateCreationAssignableCashierBranches(UUID)}
     * (FK02-C) bevált is_vault=false szűrőjét tükrözi. A branch JOIN FETCH-elt, így OSIV-off
     * mellett is biztonságos (a totals/position aggregátumok szándékosan a sima findByCompanyId-n
     * maradnak — az külön üzleti döntés).
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.company.id = :companyId " +
           "AND (cb.branch.isVault IS NULL OR cb.branch.isVault = false) " +
           "ORDER BY cb.branch.name, cb.currency.displayOrder")
    List<CashBalance> findByCompanyIdExcludingVault(@Param("companyId") UUID companyId);

    /**
     * Alacsony készletű egyenlegek (JOIN FETCH)
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.company.id = :companyId " +
           "AND cb.currentBalance <= cb.minBalance " +
           "AND cb.minBalance IS NOT NULL")
    List<CashBalance> findLowBalances(@Param("companyId") UUID companyId);

    /**
     * E-B8 (#279): kritikus készletű egyenlegek MINDEN cégre — a scheduler security
     * context nélkül fut, ezért nincs company-szűrés (a service company-nként csoportosít
     * és cégen belüli supervisoroknak értesít, így nincs cross-tenant szivárgás).
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.currentBalance <= cb.minBalance " +
           "AND cb.minBalance IS NOT NULL")
    List<CashBalance> findAllLowBalances();

    /**
     * Magas készletű egyenlegek (JOIN FETCH)
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.company.id = :companyId " +
           "AND cb.currentBalance >= cb.maxBalance " +
           "AND cb.maxBalance IS NOT NULL")
    List<CashBalance> findHighBalances(@Param("companyId") UUID companyId);

    /**
     * Iroda osszes HUF egyenlege (napzaras ellenorzeshez).
     */
    @Query("SELECT COALESCE(SUM(cb.currentBalance), 0) FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId AND cb.currency.code = 'HUF'")
    java.math.BigDecimal sumCurrentBalanceHuf(@Param("branchId") UUID branchId);

    /**
     * Egyenleg keresése fiók és valuta kód szerint (egyeztetéshez).
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId AND cb.currency.code = :currencyCode")
    Optional<CashBalance> findByBranchIdAndCurrencyCode(
        @Param("branchId") UUID branchId,
        @Param("currencyCode") String currencyCode);

    /**
     * Összes egyenleg egy fiókhoz a napi egyeztetéshez (currency code-dal).
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId")
    List<CashBalance> findAllByBranchId(@Param("branchId") UUID branchId);
}

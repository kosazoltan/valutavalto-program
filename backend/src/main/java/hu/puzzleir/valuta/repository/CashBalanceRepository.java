package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CashBalance;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
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
     * Egyenleg keresése fiók, valuta ÉS cég alapján — defense-in-depth tenant-scope.
     *
     * 2026-07-10 (GLM-review lelet, INVSTOCK-kör): a korábbi findByBranchIdAndCurrencyId
     * companyId-predikátum nélkül futott. Nem volt direkt IDOR (a branchId minden hívónál
     * JWT-ből vagy company-validált Branch entityből jött), de pénz-út lekérdezés a repo
     * konvenciója szerint nem élhet tenant-szűrés nélkül — a companyId így elírt/rosszul
     * megbízott branchId esetén is üres találatot (fail-closed) kényszerít.
     * A companyId forrása hívóhely-függő: JWT (SecurityUtils.getCurrentCompanyId) a
     * request-scoped hívóknál, validált Branch.company a startup/entity-alapúaknál.
     */
    Optional<CashBalance> findByBranchIdAndCurrencyIdAndCompanyId(
            UUID branchId, Long currencyId, UUID companyId);

    /**
     * Egyenleg keresése fiók és valuta alapján — JOIN FETCH a lazy branch/currency proxy ellen.
     *
     * 2026-05-27 (live-API teszt #865): a GET /cash-balances/code/{code} és /currency/{id}
     * a derived findByBranchIdAndCurrencyId-t használta (lazy branch+currency), majd a
     * controller a session lezárása UTÁN (OSIV=false) hívta a CashBalanceMapper.toDto-t →
     * LazyInitializationException (Branch proxy, no session) → HTTP 500. A lista-végpontok
     * (findByBranchId/findByCompanyId) már JOIN FETCH-elnek; ez a single-balance párjuk.
     * 2026-07-10 (4. kör, CASHBAL-BRANCH-SCOPED): companyId-predikátum — defense-in-depth tenant-scope.
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.branch.id = :branchId AND cb.currency.id = :currencyId " +
           "AND cb.company.id = :companyId")
    Optional<CashBalance> findByBranchIdAndCurrencyIdAndCompanyIdWithDetails(
            @Param("branchId") UUID branchId, @Param("currencyId") Long currencyId,
            @Param("companyId") UUID companyId);

    /**
     * Egyenleg keresése PESSIMISTIC_WRITE lockkal (race condition védelem) — cég-szűrt.
     * CRITICAL FIX: Párhuzamos készletmódosítás megakadályozása.
     *
     * 2026-07-10 (#1389 follow-up): companyId-predikátum — pénz-út lock-lekérdezés nem élhet
     * tenant-szűrés nélkül (defense-in-depth; cross-tenant sor üres találat → fail-closed).
     * A lock-akvirálási SORRENDET a CashLockOrdering determinálja, a predikátum azt nem érinti.
     * A companyId forrása hívóhely-függő: JWT a request-scoped hívóknál, entity-derived a
     * scheduler/entity-alapúaknál (pl. ReservationService.restoreCurrencyStock).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT cb FROM CashBalance cb WHERE cb.branch.id = :branchId " +
           "AND cb.currency.id = :currencyId AND cb.company.id = :companyId")
    Optional<CashBalance> findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(
            @Param("branchId") UUID branchId, @Param("currencyId") Long currencyId,
            @Param("companyId") UUID companyId);

    /**
     * INVSTOCK-ROLLBACK fix: race-mentes sor-garantálás. Az ON CONFLICT DO NOTHING
     * kiváltja a korábbi saveAndFlush + DIVE-catch mintát, így a tranzakció nem lesz
     * rollback-only; a hívó ezután lockolt újraolvasással könyvel a garantált sorra.
     */
    @Modifying
    @Query(value = """
            INSERT INTO cash_balance
                (company_id, branch_id, currency_id, current_balance, opening_balance, created_at, version)
            VALUES (:companyId, :branchId, :currencyId, 0, 0, NOW(), 0)
            ON CONFLICT (branch_id, currency_id) DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(@Param("companyId") UUID companyId,
                       @Param("branchId") UUID branchId,
                       @Param("currencyId") Long currencyId);

    /**
     * Összes egyenleg egy fiókhoz (JOIN FETCH a lazy proxy hiba elkerüléséhez).
     * 2026-07-10 (4. kör, CASHBAL-BRANCH-SCOPED): companyId-predikátum — defense-in-depth tenant-scope.
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "JOIN FETCH cb.branch " +
           "JOIN FETCH cb.currency " +
           "JOIN FETCH cb.company " +
           "WHERE cb.branch.id = :branchId AND cb.company.id = :companyId " +
           "ORDER BY cb.currency.displayOrder")
    List<CashBalance> findByBranchIdAndCompanyId(
            @Param("branchId") UUID branchId, @Param("companyId") UUID companyId);

    /**
     * Issue #110 / Sourcery feedback: létezik-e cash_balance erre a branch-re?
     *
     * Könnyebb query — csak COUNT, nem lekéri az összes rekordot.
     * Használat: SessionOpenService lazy-init check.
     * 2026-07-10 (4. kör, CASHBAL-BRANCH-SCOPED): companyId-predikátum — defense-in-depth tenant-scope.
     */
    @Query("SELECT CASE WHEN COUNT(cb) > 0 THEN true ELSE false END FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId AND cb.company.id = :companyId")
    boolean existsByBranchIdAndCompanyId(
            @Param("branchId") UUID branchId, @Param("companyId") UUID companyId);

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
           "LEFT JOIN cb.branch.branchType bt " +
           "WHERE cb.company.id = :companyId " +
           "AND (cb.branch.isVault IS NULL OR cb.branch.isVault = false) " +
           "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') " +
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
     * 2026-07-10 (4. kör, CASHBAL-BRANCH-SCOPED): companyId-predikátum — defense-in-depth tenant-scope.
     */
    @Query("SELECT COALESCE(SUM(cb.currentBalance), 0) FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId AND cb.currency.code = 'HUF' " +
           "AND cb.company.id = :companyId")
    java.math.BigDecimal sumCurrentBalanceHufByBranchIdAndCompanyId(
            @Param("branchId") UUID branchId, @Param("companyId") UUID companyId);

    /**
     * FK-063 FR-1 (2026-07-24): pénznem-kódok, amelyekből az adott pénztári branch-nek
     * NEM-NULLA készlete van — a pénztári napi zárás multi-devizás becímletezésének
     * forrás-lekérdezése. Cég-szűrt (defense-in-depth tenant-scope, cross-tenant
     * branchId üres listát ad — fail-closed). Skalár projekció (currency.code),
     * így OSIV-off mellett sincs lazy-proxy kockázat.
     */
    @Query("SELECT cb.currency.code FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId AND cb.company.id = :companyId " +
           "AND cb.currentBalance <> 0 " +
           "ORDER BY cb.currency.displayOrder")
    List<String> findCurrencyCodesWithNonZeroBalance(
            @Param("branchId") UUID branchId, @Param("companyId") UUID companyId);

    /**
     * Egyenleg keresése fiók és valuta kód szerint (egyeztetéshez).
     * 2026-07-10 (4. kör, CASHBAL-BRANCH-SCOPED): companyId-predikátum — defense-in-depth tenant-scope.
     */
    @Query("SELECT cb FROM CashBalance cb " +
           "WHERE cb.branch.id = :branchId AND cb.currency.code = :currencyCode " +
           "AND cb.company.id = :companyId")
    Optional<CashBalance> findByBranchIdAndCurrencyCodeAndCompanyId(
        @Param("branchId") UUID branchId,
        @Param("currencyCode") String currencyCode,
        @Param("companyId") UUID companyId);

    /**
     * FKH-029 FR-3 (read-only megfigyelhetőség): azok az AKTÍV értéktári branch-ek, amelyeknek
     * hiányzik {@code cash_balance} soruk legalább egy aktív valutára.
     *
     * <p>A V371 migráció után ez üres — bármely találat új Értéktárra vagy újonnan aktivált
     * valutára utal, amit a {@code TransferService} lazy get-or-create ága már kezel, de
     * érdemes riasztani, mert a hiány a napzárás/riport útvonalakon is felszínre jöhet.</p>
     *
     * <p>A job rendszerszintű (nincs request-scope JWT), ezért CÉGFÜGGETLEN — a visszaadott
     * sorok tartalmazzák a cég kódját is. Csak SELECT, semmit nem módosít.</p>
     *
     * @return sorok: {@code [companyCode, branchCode, missingCurrencyCodes(csv), missingCount]}
     */
    @Query(value = """
            SELECT co.code                       AS company_code,
                   b.code                        AS branch_code,
                   string_agg(c.code, ',' ORDER BY c.code) AS missing_currencies,
                   count(*)                      AS missing_count
              FROM branch b
              JOIN company co ON co.id = b.company_id
              CROSS JOIN currency c
             WHERE b.is_vault = TRUE
               AND b.is_active = TRUE
               AND c.is_active = TRUE
               AND NOT EXISTS (
                   SELECT 1 FROM cash_balance cb
                    WHERE cb.branch_id = b.id
                      AND cb.currency_id = c.id
               )
             GROUP BY co.code, b.code
             ORDER BY co.code, b.code
            """, nativeQuery = true)
    List<Object[]> findVaultBranchesWithMissingCashBalance();
}

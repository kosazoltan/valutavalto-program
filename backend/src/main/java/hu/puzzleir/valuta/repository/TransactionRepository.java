package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Transaction repository.
 */
@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    /**
     * Bizonylat keresése szám alapján (JOIN FETCH a lazy proxy hiba elkerüléséhez)
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.receiptNumber = :receiptNumber AND t.company.id = :companyId")
    Optional<Transaction> findByReceiptNumberAndCompanyId(
        @Param("receiptNumber") String receiptNumber,
        @Param("companyId") UUID companyId);

    /**
     * Napi tranzakciók egy fiókhoz (JOIN FETCH a lazy proxy hiba elkerüléséhez).
     *
     * <p>MEGJEGYZES: a branch.id uniq garantalva van, es branch->company FK biztositja az
     * implicit tenant-elvalasztast, ezert nincs explicit companyId szures.</p>
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Napi tranzakciók egy fiókhoz CEG-en BELUL (explicit multi-tenant szures).
     * Akkor hasznald, amikor a branchId a felhasznalotol jon (IDOR veszely).
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByCompanyIdAndBranchAndDate(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Tranzakciók pénztároshoz.
     *
     * 2026-04-29 v2.3.28 (B17 multi-tenancy extend — defenzív hardening):
     * Bevezetjük a `companyId` szűrőt is, hogy a worker.id elméleti collision
     * (cross-company workerId) NE okozzon adatszivárgást. A worker.id BIGINT
     * sequence egyedi a system-en, de defenzív Spring Security best-practice
     * szerint a multi-tenant szűrőt minden lekérdezés-réteg-en alkalmazni kell.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.worker.id = :workerId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByWorkerAndDate(
        @Param("companyId") UUID companyId,
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    /**
     * H-7: Pénztáros tranzakciói egy időszakban (N+1 kiváltása)
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "ORDER BY t.transactionDate, t.transactionTime")
    List<Transaction> findByWorkerIdAndTransactionDateBetween(
        @Param("workerId") Long workerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Tranzakciók típus szerint
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate")
    List<Transaction> findByTypeAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("type") TransactionType type,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Napi sztornók száma — iroda szinten.
     *
     * 2026-04-29 v2.3.28 (B17 multi-tenancy extend — defenzív hardening):
     * `companyId` szűrő hozzáadva, hogy a branch.id elméleti collision (cross-company
     * branchId — bár UUID egyedi, defenzív szempontból is) NE okozzon szivárgást.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = 'REVERSAL'")
    long countReversalsByBranchAndDate(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Napi sztornók száma — pénztáros (cashier/worker) szinten.
     * Legacy: a sztornó limit irodánként ÉS pénztárosonként is érvényes.
     *
     * 2026-04-29 v2.3.30 (Sourcery PR #293 consistency align):
     * `companyId` param hozzáadva — consistent multi-tenant query API
     * (countReversalsByBranchAndDate-vel azonos pattern).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.worker.id = :workerId " +
           "AND t.transactionType = 'REVERSAL'")
    long countReversalsByBranchAndWorkerAndDate(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    /**
     * Napi forgalom összeg
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = :type " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumDailyTurnover(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type
    );

    /**
     * Napi forgalom összeg — adott valutához szűrve (napi mérleg számításhoz).
     */
    @Query("SELECT COALESCE(SUM(t.currencyAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = :type " +
           "AND t.currency.code = :currencyCode " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumDailyTurnoverByCurrency(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type,
        @Param("currencyCode") String currencyCode
    );

    /**
     * Következő bizonylat szám generálásához
     */
    @Query("SELECT MAX(t.receiptNumber) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.receiptNumber LIKE :prefix%")
    Optional<String> findMaxReceiptNumber(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("prefix") String prefix
    );

    /**
     * Tranzakciók lapozással (JOIN FETCH a lazy proxy hiba elkerüléséhez).
     *
     * 2026-04-29 v2.3.25 (B17 multi-tenant hardening):
     * KÖTELEZŐ `companyId` ÉS `branchId` szűrő — defenzív IDOR-megelőzés.
     * Korábbi `(:branchId IS NULL OR t.branch.id = :branchId)` ág eltávolítva,
     * mert ha bármely jövőbeli hívó `null`-t ad → cross-branch adatszivárgás.
     * A null-check most a hívó felelőssége (Spring Security: `@NonNull`).
     */
    @Query(value = "SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC",
           countQuery = "SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.branch.id = :branchId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type)")
    Page<Transaction> findWithFilters(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("type") TransactionType type,
        Pageable pageable
    );

    /**
     * 2026-04-29 v2.3.26 (Codex P1 PR #290 follow-up):
     * COMPANY-WIDE tranzakció-lekérdezés, branchId NÉLKÜL — csak a saját company-n belül.
     *
     * Use case: cég-szintű statisztikák (top customers, frequent customers, MNB
     * aggregate report). NEM keverendő össze a `findWithFilters` branch-scoped
     * query-vel, ami IDOR-érzékeny (B17 hardening).
     *
     * Security: a hívó controller-nek kell `@PreAuthorize`-szal védenie ezt a
     * metódust (csak MANAGER+ vagy ADMIN role használhatja, NEM CASHIER).
     */
    @Query(value = "SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "LEFT JOIN FETCH t.originalTransaction " +
           "WHERE t.company.id = :companyId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC",
           countQuery = "SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type)")
    Page<Transaction> findCompanyWideWithFilters(
        @Param("companyId") UUID companyId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate,
        @Param("type") TransactionType type,
        Pageable pageable
    );

    /**
     * Ügyfél tranzakciói
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findByCustomerId(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId
    );

    /**
     * Batch: aktiv tranzakciok lekerese TOBB irodahoz egy napon.
     * N+1 query kivaltasa korzet szintu MNB aggregacional.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id IN :branchIds " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.branch.id ASC, t.transactionTime DESC")
    List<Transaction> findActiveByBranchIdsAndDate(
        @Param("branchIds") List<UUID> branchIds,
        @Param("date") LocalDate date
    );

    /**
     * Aktív (nem sztornózott) tranzakciók
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findActiveByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Aktív tranzakciók lekérése irodához, dátumtartományra.
     * NAV PTGSZLAH havi jelentéshez szükséges.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate ASC, t.transactionTime ASC")
    List<Transaction> findActiveByBranchAndDateRange(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Napi tranzakció számláló típus szerint
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = :type " +
           "AND t.status = 'COMPLETED'")
    long countByBranchIdAndTransactionDateAndTransactionType(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type
    );

    // ============ AML QUERY-K ============

    /**
     * Ugyfel eves gongyolesi osszeg (AML).
     * Legacy: BIGCTRL.DLL — eves kumulativ osszeg
     *
     * <p>Audit P0.8 (V177, 2026-05-03): `financial_effective = TRUE` szuro hozzaadva,
     * hogy a parent CONVERSION sor NE duplazza a child convBuy + convSell osszeget.</p>
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerAnnualTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Ugyfel napi osszeg (AML gyanusagi ellenorzes).
     *
     * <p>Audit P0.8 (V177, 2026-05-03): `financial_effective = TRUE` szuro a CONVERSION
     * dupla-szamolas megelozeseert.</p>
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerDailyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("date") LocalDate date
    );

    // ============ AML LEGACY QUERY-K (BIGCTRL.DLL) ============

    /**
     * Heti göngyölés: ügyfél elmúlt 7 nap HUF összege.
     * Legacy: HETIOSSZ mező — _diff < 8 → _hasforint + _hetiforint
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerWeeklyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Sprint 6.2 C2 audit: 8 napos gordulo limit felett levo ugyfelek.
     * Visszaadja a customerId-ket es a gongyolt osszeget az elmult 8 napra,
     * ahol a gongyolt osszeg >= thresholdHuf.
     *
     * Hasznalt: Compliance dashboard, Pmt. kotelezo audit.
     */
    @Query("SELECT t.customerId, COALESCE(SUM(t.hufAmount), 0) as total " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId IS NOT NULL " +
           "AND t.customerId <> '' " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true " +
           "GROUP BY t.customerId " +
           "HAVING COALESCE(SUM(t.hufAmount), 0) >= :thresholdHuf " +
           "ORDER BY total DESC")
    java.util.List<Object[]> findRollingWindowAuditCandidates(
        @Param("companyId") UUID companyId,
        @Param("sinceDate") LocalDate sinceDate,
        @Param("thresholdHuf") BigDecimal thresholdHuf
    );

    /**
     * Éves maximum tranzakció összeg.
     * Legacy: EVIMAX mező
     */
    @Query("SELECT COALESCE(MAX(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :yearStart AND :yearEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal findCustomerYearlyMax(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("yearStart") LocalDate yearStart,
        @Param("yearEnd") LocalDate yearEnd
    );

    /**
     * Negyedéves tranzakciószám.
     * Legacy: BIGCTRL.DLL TranzTipus 4 — 4+ tranzakció a negyedévben
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :quarterStart AND :quarterEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    long countCustomerQuarterlyTransactions(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("quarterStart") LocalDate quarterStart,
        @Param("quarterEnd") LocalDate quarterEnd
    );

    /**
     * Negyedéves HUF összeg.
     * Legacy: _negyedevFt >= 25.000.000
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :quarterStart AND :quarterEnd " +
           "AND t.status = 'COMPLETED' " +
           "AND t.financialEffective = true")
    BigDecimal sumCustomerQuarterlyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("quarterStart") LocalDate quarterStart,
        @Param("quarterEnd") LocalDate quarterEnd
    );

    /**
     * Havi tranzakciók branch-hez (havi záráshoz).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate, t.transactionTime")
    List<Transaction> findByBranchAndMonth(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi összesítő: vétel HUF összeg branch-hez.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.transactionType IN ('BUY', 'WESTERN_UNION_RECEIVE', 'MONEYGRAM_RECEIVE') " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumMonthlyBuyHuf(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi összesítő: eladás HUF összeg branch-hez.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.transactionType IN ('SELL', 'WESTERN_UNION_SEND', 'MONEYGRAM_SEND') " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumMonthlySellHuf(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi kezelési díj összeg.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumMonthlyHandlingFees(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    /**
     * Havi tranzakciószám.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED'")
    long countMonthlyTransactions(
        @Param("branchId") UUID branchId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    // ============ HANDLING FEE QUERY-K (HIGH FIX #11, #12) ============

    /**
     * HIGH FIX #11: SHK (saját hatáskörű kedvezmény) napi felhasználás számlálása.
     * discountTypeCode=4 → SHK kedvezmény a legacy rendszerben.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.discountTypeCode = 4 " +
           "AND t.status = 'COMPLETED'")
    long countShkTransactionsToday(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * HIGH FIX #12: Custom fee (egyedi kezdőjegy) napi felhasználás számlálása.
     * discountTypeCode=20 → egyedi kezdőjegy a legacy rendszerben.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.discountTypeCode = 20 " +
           "AND t.status = 'COMPLETED'")
    long countCustomFeeTransactionsToday(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    // ============ GAP 1: NAPI KEDVEZMÉNY LIMIT ============

    /**
     * Pénztáros napi kedvezményes tranzakcióinak száma.
     * Legacy: napi 5 db egyedi ráta kedvezmény limit pénztárosonként.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.transactionDate = :date " +
           "AND t.discountPercent > 0 " +
           "AND t.status = 'COMPLETED'")
    long countDailyDiscountsByWorker(
        @Param("workerId") Long workerId,
        @Param("date") LocalDate date
    );

    // ============ NAPZARAS QUERY-K ============

    /**
     * Napi kezelesi dij osszeg (napzaras ellenorzeshez).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumDailyHandlingFees(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Nem jelentett tranzakciok szama (NAV kontroll).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "AND t.printed = false")
    long countUnreportedTransactions(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * WU tranzakciok MTCN szam nelkul.
     * CRITICAL FIX (Eszter review): LIKE parameterezve SQL injection ellen.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.mtcn IS NULL " +
           "AND t.referenceNumber LIKE :refPrefix")
    List<Transaction> findByBranchIdAndTransactionDateAndMtcnIsNull(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("refPrefix") String refPrefix
    );

    /**
     * Összes tranzakció egy irodához (készlet regeneráláshoz)
     */
    @Query("SELECT t FROM Transaction t WHERE t.branch.id = :branchId ORDER BY t.transactionDate")
    List<Transaction> findByBranchId(@Param("branchId") UUID branchId);

    // ============ BATCH 3: DEKÁD + TURNOVER + COMPETITION QUERY-K ============

    /**
     * Batch 3: HUF összeg branch + típus + időszak (DateTime) alapján.
     * Dekádjelentés és turnover szolgáltatáshoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByBranchAndTypeAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("txType") String txType,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Batch 3: Kezelési díj összeg branch + időszak (transactionDate).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumFeeByBranchAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Batch 3: Tranzakció szám branch + időszak (transactionDate).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    long countByBranchAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Batch 3: HUF összeg company + típus + időszak (DateTime).
     * Cégszintű turnover riporthoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByCompanyAndTypeAndPeriod(
        @Param("companyId") UUID companyId,
        @Param("txType") String txType,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Batch 3: Kezelési díj összeg company + időszak (DateTime).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumFeeByCompanyAndPeriod(
        @Param("companyId") UUID companyId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Batch 3: HUF összeg worker + időszak (Competition).
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByWorkerAndPeriod(
        @Param("workerId") Long workerId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    /**
     * Batch 3: Tranzakció szám worker + időszak (Competition).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.createdAt BETWEEN :from AND :to " +
           "AND t.status = 'COMPLETED'")
    long countByWorkerAndPeriod(
        @Param("workerId") Long workerId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to
    );

    // ============ BATCH 7A: AML + NAV REPORT QUERY-K ============

    /**
     * Ügyfél elmúlt 30 nap tranzakcióinak összege.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumCustomerTotalSince(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Ügyfél elmúlt 30 nap tranzakciószáma.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate >= :sinceDate " +
           "AND t.status = 'COMPLETED'")
    long countCustomerTransactionsSince(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Ügyfél napi tranzakciószáma (structuring detektálás).
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED'")
    long countCustomerDailyTransactions(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("date") LocalDate date
    );

    /**
     * Ügyfél napi tranzakcióinak listája (structuring detektálás).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionTime")
    List<Transaction> findCustomerDailyTransactions(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("date") LocalDate date
    );

    /**
     * NAV adatszolgáltatás: 2M+ Ft tranzakciók adott napon, company szinten.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate = :date " +
           "AND t.hufAmount >= :threshold " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.hufAmount DESC")
    List<Transaction> findReportableTransactions(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date,
        @Param("threshold") BigDecimal threshold
    );

    /**
     * MNB riport: aktív tranzakciók company + dátum alapján (branch-független).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionTime")
    List<Transaction> findActiveByCompanyAndDate(
        @Param("companyId") UUID companyId,
        @Param("date") LocalDate date
    );

    /**
     * MNB riport: aktív tranzakciók company + hónap alapján.
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :monthStart AND :monthEnd " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate, t.transactionTime")
    List<Transaction> findActiveByCompanyAndMonth(
        @Param("companyId") UUID companyId,
        @Param("monthStart") LocalDate monthStart,
        @Param("monthEnd") LocalDate monthEnd
    );

    // ============ ÉRTÉKTÁR MODUL — KONSZOLIDÁLT RIPORT QUERY-K ============

    /**
     * Tranzakciószám branch + típus + dátum intervallum.
     * Értéktár konszolidált riporthoz.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    int countByBranchIdAndTransactionTypeAndTransactionDateBetween(
        @Param("branchId") UUID branchId,
        @Param("type") TransactionType type,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * HUF összeg branch + típus + dátum intervallum.
     * Értéktár konszolidált riporthoz.
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumHufAmountByBranchIdAndTypeAndDateBetween(
        @Param("branchId") UUID branchId,
        @Param("type") TransactionType type,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Kezelési díj összeg branch + dátum intervallum.
     * Értéktár konszolidált riporthoz.
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumFeesByBranchIdAndDateBetween(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    // ============ REPORT OPTIMIZATION QUERY-K ============

    /**
     * P2-14: Kezelési díj összesítő GROUP BY lekérdezés (N+1 kiváltása).
     * Visszaad: [transactionDate, currencyCode, SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.transactionDate, t.currency.code, SUM(t.handlingFee), COUNT(t) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED' " +
           "AND t.handlingFee > 0 " +
           "GROUP BY t.transactionDate, t.currency.code " +
           "ORDER BY t.transactionDate ASC")
    List<Object[]> findHandlingFeeSummaryByBranchAndDateRange(
        @Param("branchId") UUID branchId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    // ============ TURNOVER BREAKDOWN QUERY-K ============

    /**
     * Valuta + típus szerinti bontás — forgalom riporthoz.
     * Sztornózott (REVERSED, CANCELLED) tranzakciókat kizárja.
     * Visszaad: [currencyCode, transactionType, SUM(currencyAmount), SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.currency.code, CAST(t.transactionType AS string), " +
           "SUM(t.currencyAmount), SUM(t.hufAmount), SUM(t.handlingFee), COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "GROUP BY t.currency.code, t.transactionType " +
           "ORDER BY t.currency.code, t.transactionType")
    List<Object[]> groupByCurrencyAndTypeForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Pénztáros szerinti bontás — forgalom riporthoz.
     * Sztornózott (REVERSED, CANCELLED) tranzakciókat kizárja.
     * Visszaad: [workerId, workerName, SUM(hufAmount), SUM(handlingFee), COUNT(id)]
     */
    @Query("SELECT t.worker.id, t.worker.name, " +
           "SUM(t.hufAmount), SUM(t.handlingFee), COUNT(t.id) " +
           "FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED') " +
           "GROUP BY t.worker.id, t.worker.name " +
           "ORDER BY t.worker.name")
    List<Object[]> groupByWorkerForBranch(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * HUF összeg branch + típus + időszak, sztornókat kizárva.
     * Turnover riport főösszegekhez (REVERSED/CANCELLED nélkül).
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND CAST(t.transactionType AS string) = :txType " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumHufAmountByBranchAndTypeAndPeriodExcludingReversals(
        @Param("branchId") UUID branchId,
        @Param("txType") String txType,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Kezelési díj összeg branch + időszak, sztornókat kizárva.
     * Turnover riport főösszegekhez (REVERSED/CANCELLED nélkül).
     */
    @Query("SELECT COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status NOT IN ('REVERSED', 'CANCELLED')")
    BigDecimal sumFeeByBranchAndPeriodExcludingReversals(
        @Param("branchId") UUID branchId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * Napi zárás ellenőrzés: van-e PENDING státuszú tranzakció az adott irodában.
     */
    boolean existsByBranchIdAndStatus(UUID branchId, TransactionStatus status);

    /**
     * Ugyfel tranzakcioi okmany szam alapjan (multi-tenant).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerDocumentNumber = :docNumber " +
           "AND t.status = 'COMPLETED' " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findByCompanyIdAndCustomerDocumentNumber(
        @Param("companyId") UUID companyId,
        @Param("docNumber") String docNumber
    );

    /**
     * Ugyfel tranzakcioi okmany szam es datum alapjan (multi-tenant).
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerDocumentNumber = :docNumber " +
           "AND t.status = 'COMPLETED' " +
           "AND (:dateFrom IS NULL OR t.transactionDate >= :dateFrom) " +
           "AND (:dateTo IS NULL OR t.transactionDate <= :dateTo) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findByCompanyIdAndCustomerDocumentNumberAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("docNumber") String docNumber,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    // ============ TRB EXPORT (legacy G4) ============

    /**
     * Összeg GROUP BY valutanem egy irodára, típusra, napra.
     * TRB ügyfélforgalom export — legacy unit5.pas UgyfPrepare.
     * Returns Object[]{currencyCode, sumAmount}
     */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.currencyAmount), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = :type " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "GROUP BY t.currency.code " +
           "ORDER BY t.currency.code")
    List<Object[]> sumAmountByCurrencyAndBranchAndTypeAndDate(
        @Param("branchId") UUID branchId,
        @Param("type") TransactionType type,
        @Param("date") LocalDate date
    );

    /**
     * Bankkártyás eladások összege GROUP BY valutanem.
     * TRB export — legacy unit5.pas bankkartyás/készpénzes megkülönböztetés.
     * Returns Object[]{currencyCode, cardAmount, cardFee}
     */
    @Query("SELECT t.currency.code, COALESCE(SUM(t.hufAmount), 0), COALESCE(SUM(t.handlingFee), 0) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionType = 'SELL' " +
           "AND t.paymentMethod = hu.puzzleir.valuta.entity.PaymentMethod.CARD " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED' " +
           "GROUP BY t.currency.code")
    List<Object[]> sumCardSalesByCurrencyAndBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    // ============ SYNC RESTORE (szerver → pénztár visszaállítás) ============

    /**
     * Branch összes tranzakciója (darabszám).
     */
    long countByBranchId(UUID branchId);

    /**
     * Branch tranzakciói egy dátum után, dátum szerint rendezve.
     * Szerver → Pénztár restore endpoint.
     */
    List<Transaction> findByBranchIdAndTransactionDateAfterOrderByTransactionDateAsc(
        UUID branchId, LocalDate since
    );

    /**
     * Legrégebbi tranzakció dátuma egy branch-ben.
     */
    // ============ B2: CASHIER KPI DASHBOARD ============

    /**
     * B2: Penztaros KPI aggregalas ceg szinten, adott idoszakra.
     * GROUP BY worker, visszaad:
     *   [0] workerId (Long)
     *   [1] workerName (String)
     *   [2] txCount (long) - osszes tranzakcio (aktiv)
     *   [3] buyCount (long)
     *   [4] sellCount (long)
     *   [5] reversalCount (long) - REVERSAL tipusu tranzakciok szama
     *   [6] totalHuf (BigDecimal) - BUY+SELL osszeg
     *   [7] buyHuf (BigDecimal)
     *   [8] sellHuf (BigDecimal)
     *   [9] totalFees (BigDecimal)
     *   [10] customerCount (long) - egyedi ugyfel azonositok szama
     *
     * Csak COMPLETED tranzakciok. A REVERSED statusz sorok nem szamolodnak.
     */
    @Query("SELECT w.id, w.name, " +
           "COUNT(t), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.REVERSAL THEN 1 ELSE 0 END), " +
           "COALESCE(SUM(CASE WHEN t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, hu.puzzleir.valuta.entity.TransactionType.SELL) THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(t.handlingFee), 0), " +
           "COUNT(DISTINCT t.customerId) " +
           "FROM Transaction t JOIN t.worker w " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED " +
           "GROUP BY w.id, w.name " +
           "ORDER BY w.name ASC")
    List<Object[]> cashierKpiByCompanyAndDateRange(
        @Param("companyId") UUID companyId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    /**
     * B2: Ceges osszesito penztaros KPI-khez (felette a cards).
     * Visszaad: [txCount, buyCount, sellCount, reversalCount, totalHuf, totalFees, workerCount, customerCount]
     */
    @Query("SELECT " +
           "COUNT(t), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.BUY THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.SELL THEN 1 ELSE 0 END), " +
           "SUM(CASE WHEN t.transactionType = hu.puzzleir.valuta.entity.TransactionType.REVERSAL THEN 1 ELSE 0 END), " +
           "COALESCE(SUM(CASE WHEN t.transactionType IN (hu.puzzleir.valuta.entity.TransactionType.BUY, hu.puzzleir.valuta.entity.TransactionType.SELL) THEN t.hufAmount ELSE 0 END), 0), " +
           "COALESCE(SUM(t.handlingFee), 0), " +
           "COUNT(DISTINCT t.worker.id), " +
           "COUNT(DISTINCT t.customerId) " +
           "FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.transactionDate BETWEEN :dateFrom AND :dateTo " +
           "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED")
    Object[] cashierKpiCompanyTotals(
        @Param("companyId") UUID companyId,
        @Param("dateFrom") LocalDate dateFrom,
        @Param("dateTo") LocalDate dateTo
    );

    @Query("SELECT MIN(t.transactionDate) FROM Transaction t WHERE t.branch.id = :branchId")
    LocalDate findEarliestDateByBranchId(@Param("branchId") UUID branchId);

    /**
     * Legújabb tranzakció dátuma egy branch-ben.
     */
    @Query("SELECT MAX(t.transactionDate) FROM Transaction t WHERE t.branch.id = :branchId")
    LocalDate findLatestDateByBranchId(@Param("branchId") UUID branchId);

    /**
     * v2.3.48 (B7 audit fix): Bizonylatok lista companyId-szintu listazasa.
     * Hasznalata: a /api/v1/receipts endpoint synthesize Receipt-shape DTO-kat
     * a Transaction tablabol, mert a Receipt tabla uresen marad (nincs explicit
     * Receipt insert a TransactionService.processBuy/Sell flow-ban).
     *
     * Limit (top 500 most recent) — a frontend ReceiptPage NEM paginal,
     * igy a teljes listaval terhelnenk a UI-t.
     */
    @Query("SELECT t FROM Transaction t " +
           "JOIN FETCH t.branch " +
           "JOIN FETCH t.company " +
           "LEFT JOIN FETCH t.currency " +
           "LEFT JOIN FETCH t.worker " +
           "WHERE t.company.id = :companyId " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    List<Transaction> findReceiptListByCompanyId(
        @Param("companyId") UUID companyId,
        Pageable pageable);
}

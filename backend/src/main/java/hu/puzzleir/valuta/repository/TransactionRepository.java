package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Transaction;
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
     * Bizonylat keresése szám alapján
     */
    Optional<Transaction> findByReceiptNumberAndCompanyId(String receiptNumber, UUID companyId);

    /**
     * Napi tranzakciók egy fiókhoz
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Tranzakciók pénztároshoz
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.worker.id = :workerId " +
           "AND t.transactionDate = :date " +
           "ORDER BY t.transactionTime DESC")
    List<Transaction> findByWorkerAndDate(
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
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.transactionType = 'REVERSAL'")
    long countReversalsByBranchAndDate(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date
    );

    /**
     * Napi sztornók száma — pénztáros (cashier/worker) szinten.
     * Legacy: a sztornó limit irodánként ÉS pénztárosonként is érvényes.
     */
    @Query("SELECT COUNT(t) FROM Transaction t " +
           "WHERE t.branch.id = :branchId " +
           "AND t.transactionDate = :date " +
           "AND t.worker.id = :workerId " +
           "AND t.transactionType = 'REVERSAL'")
    long countReversalsByBranchAndWorkerAndDate(
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
     * Tranzakciók lapozással
     */
    @Query("SELECT t FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND (:branchId IS NULL OR t.branch.id = :branchId) " +
           "AND (:startDate IS NULL OR t.transactionDate >= :startDate) " +
           "AND (:endDate IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:type IS NULL OR t.transactionType = :type) " +
           "ORDER BY t.transactionDate DESC, t.transactionTime DESC")
    Page<Transaction> findWithFilters(
        @Param("companyId") UUID companyId,
        @Param("branchId") UUID branchId,
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
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "AND t.status = 'COMPLETED'")
    BigDecimal sumCustomerAnnualTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    /**
     * Ugyfel napi osszeg (AML gyanusagi ellenorzes).
     */
    @Query("SELECT COALESCE(SUM(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate = :date " +
           "AND t.status = 'COMPLETED'")
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
           "AND t.status = 'COMPLETED'")
    BigDecimal sumCustomerWeeklyTotal(
        @Param("companyId") UUID companyId,
        @Param("customerId") String customerId,
        @Param("sinceDate") LocalDate sinceDate
    );

    /**
     * Éves maximum tranzakció összeg.
     * Legacy: EVIMAX mező
     */
    @Query("SELECT COALESCE(MAX(t.hufAmount), 0) FROM Transaction t " +
           "WHERE t.company.id = :companyId " +
           "AND t.customerId = :customerId " +
           "AND t.transactionDate BETWEEN :yearStart AND :yearEnd " +
           "AND t.status = 'COMPLETED'")
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
           "AND t.status = 'COMPLETED'")
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
           "AND t.status = 'COMPLETED'")
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
}

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
     * Napi sztornók száma
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
}

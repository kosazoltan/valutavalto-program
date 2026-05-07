package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.HandlingFeeTransaction;
import hu.puzzleir.valuta.entity.PaymentMethod;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface HandlingFeeTransactionRepository extends JpaRepository<HandlingFeeTransaction, UUID> {

    Optional<HandlingFeeTransaction> findByTransactionId(Long transactionId);

    @Query("SELECT COALESCE(SUM(h.netFee), 0) FROM HandlingFeeTransaction h " +
           "JOIN Transaction t ON t.id = h.transactionId " +
           "WHERE t.branch.id = :branchId AND h.createdAt BETWEEN :from AND :to")
    BigDecimal sumNetFeeByBranchAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to);

    @Query("SELECT h FROM HandlingFeeTransaction h " +
           "JOIN Transaction t ON t.id = h.transactionId " +
           "WHERE t.branch.id = :branchId AND h.createdAt BETWEEN :from AND :to")
    List<HandlingFeeTransaction> findByBranchAndPeriod(
        @Param("branchId") UUID branchId,
        @Param("from") LocalDateTime from,
        @Param("to") LocalDateTime to);

    @Query("SELECT t.id AS transactionId, t.paymentMethod AS paymentMethod " +
           "FROM Transaction t WHERE t.id IN :transactionIds")
    List<TransactionPaymentMethodProjection> findPaymentMethodsByTransactionIds(
        @Param("transactionIds") List<Long> transactionIds);

    interface TransactionPaymentMethodProjection {
        Long getTransactionId();
        PaymentMethod getPaymentMethod();
    }
}

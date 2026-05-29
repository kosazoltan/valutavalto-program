package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.entity.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface TransactionLineRepository extends JpaRepository<TransactionLine, Long> {

    List<TransactionLine> findByTransactionIdOrderByLineNumber(Long transactionId);

    int countByTransactionId(Long transactionId);

    void deleteByTransactionId(Long transactionId);

    /**
     * Napi forgalom (deviza-mennyiség) a MULTI-LINE bizonylatok TÉTELSORAIBÓL, valutánként
     * (Codex #903 multi-line fix). A sor valutája ({@code l.currency}) és mennyisége
     * ({@code l.banknoteCount}) a helyes per-valuta forrás; az irány a parent
     * {@code transaction.transactionType}-ból jön (sor-szintű típus nincs).
     */
    @Query("SELECT COALESCE(SUM(l.banknoteCount), 0) FROM TransactionLine l " +
           "WHERE l.transaction.branch.id = :branchId AND l.transaction.transactionDate = :date " +
           "AND l.transaction.transactionType = :type AND l.currency.code = :currencyCode " +
           "AND l.transaction.status = 'COMPLETED' AND l.transaction.multiLine = true")
    BigDecimal sumDailyLineTurnoverByCurrency(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type,
        @Param("currencyCode") String currencyCode
    );

    /** Napi forgalom FORINTOSÍTOTT összege a multi-line tétel-sorokból ({@code l.hufValue}), valutánként. */
    @Query("SELECT COALESCE(SUM(l.hufValue), 0) FROM TransactionLine l " +
           "WHERE l.transaction.branch.id = :branchId AND l.transaction.transactionDate = :date " +
           "AND l.transaction.transactionType = :type AND l.currency.code = :currencyCode " +
           "AND l.transaction.status = 'COMPLETED' AND l.transaction.multiLine = true")
    BigDecimal sumDailyLineTurnoverHufByCurrency(
        @Param("branchId") UUID branchId,
        @Param("date") LocalDate date,
        @Param("type") TransactionType type,
        @Param("currencyCode") String currencyCode
    );
}

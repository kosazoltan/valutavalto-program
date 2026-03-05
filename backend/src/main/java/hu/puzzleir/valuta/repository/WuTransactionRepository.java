package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WuTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface WuTransactionRepository extends JpaRepository<WuTransaction, UUID> {

    @Query("SELECT t FROM WuTransaction t WHERE t.branch.id = :branchId " +
           "AND (:from IS NULL OR t.transactionDate >= :from) " +
           "AND (:to IS NULL OR t.transactionDate <= :to) " +
           "ORDER BY t.transactionDate DESC")
    Page<WuTransaction> findByBranchAndDateRange(
            @Param("branchId") UUID branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to,
            Pageable pageable);

    @Query("SELECT t FROM WuTransaction t WHERE t.branch.id = :branchId " +
           "AND t.transactionDate >= :from AND t.transactionDate <= :to")
    List<WuTransaction> findAllByBranchAndDateRange(
            @Param("branchId") UUID branchId,
            @Param("from") LocalDateTime from,
            @Param("to") LocalDateTime to);
}

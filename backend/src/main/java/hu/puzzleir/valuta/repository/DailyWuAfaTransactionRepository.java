package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DailyWuAfaTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface DailyWuAfaTransactionRepository extends JpaRepository<DailyWuAfaTransaction, UUID> {

    List<DailyWuAfaTransaction> findByBranchIdAndTransactionDate(UUID branchId, LocalDate transactionDate);

    boolean existsByBranchIdAndTransactionDate(UUID branchId, LocalDate transactionDate);
}

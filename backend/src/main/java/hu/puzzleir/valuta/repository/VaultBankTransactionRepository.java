package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.VaultBankTransaction;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface VaultBankTransactionRepository extends JpaRepository<VaultBankTransaction, Long> {
    List<VaultBankTransaction> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);
    List<VaultBankTransaction> findByCompanyIdAndStatusOrderByCreatedAtDesc(UUID companyId, VaultOperationStatus status);
    List<VaultBankTransaction> findByCompanyIdAndTransactionTypeOrderByCreatedAtDesc(UUID companyId, String transactionType);
    List<VaultBankTransaction> findByCompanyIdAndCreatedAtBetweenOrderByCreatedAtDesc(UUID companyId, LocalDateTime from, LocalDateTime to);
}

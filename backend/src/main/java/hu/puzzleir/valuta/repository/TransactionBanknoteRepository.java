package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransactionBanknote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionBanknoteRepository extends JpaRepository<TransactionBanknote, Long> {

    List<TransactionBanknote> findByTransactionId(Long transactionId);

    List<TransactionBanknote> findByTransactionIdAndDirection(Long transactionId, String direction);

    List<TransactionBanknote> findByTransactionLineId(Long transactionLineId);
}

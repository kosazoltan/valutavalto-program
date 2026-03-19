package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransactionLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransactionLineRepository extends JpaRepository<TransactionLine, Long> {

    List<TransactionLine> findByTransactionIdOrderByLineNumber(Long transactionId);

    int countByTransactionId(Long transactionId);

    void deleteByTransactionId(Long transactionId);
}

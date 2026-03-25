package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Receipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ReceiptRepository extends JpaRepository<Receipt, UUID> {
    List<Receipt> findByTransactionId(UUID transactionId);
    List<Receipt> findAllByCompanyId(UUID companyId);
    List<Receipt> findByCompanyIdAndTransactionId(UUID companyId, UUID transactionId);
}

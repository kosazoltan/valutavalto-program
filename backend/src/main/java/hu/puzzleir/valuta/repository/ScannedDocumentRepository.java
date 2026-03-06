package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ScannedDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ScannedDocumentRepository extends JpaRepository<ScannedDocument, UUID> {

    List<ScannedDocument> findByCustomerIdAndIsDeletedFalseOrderByScannedAtDesc(UUID customerId);

    List<ScannedDocument> findByTransactionIdAndIsDeletedFalseOrderByScannedAtDesc(UUID transactionId);
}

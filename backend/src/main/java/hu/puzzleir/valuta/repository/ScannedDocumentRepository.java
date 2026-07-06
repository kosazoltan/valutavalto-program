package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ScannedDocumentRepository extends JpaRepository<ScannedDocument, UUID> {

    List<ScannedDocument> findByCustomerIdAndIsDeletedFalseOrderByScannedAtDesc(Long customerId);

    List<ScannedDocument> findByTransactionIdAndIsDeletedFalseOrderByScannedAtDesc(Long transactionId);

    Optional<ScannedDocument> findFirstByCustomerIdAndDocumentTypeAndIsDeletedFalseOrderByScannedAtDesc(
            Long customerId, ScannedDocumentType documentType);
}

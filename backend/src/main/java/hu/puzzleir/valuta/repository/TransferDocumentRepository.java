package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.TransferDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TransferDocumentRepository extends JpaRepository<TransferDocument, Long> {

    Optional<TransferDocument> findByDocumentNumber(String documentNumber);

    List<TransferDocument> findByStatus(TransferDocument.Status status);

    List<TransferDocument> findByCourierIdAndStatus(Long courierId, TransferDocument.Status status);

    List<TransferDocument> findByCompanyIdOrderByCreatedAtDesc(UUID companyId);

    @Query("SELECT td FROM TransferDocument td WHERE td.company.id = :companyId " +
           "AND (:status IS NULL OR td.status = :status) " +
           "AND (:courierId IS NULL OR td.courier.id = :courierId) " +
           "ORDER BY td.createdAt DESC")
    List<TransferDocument> findFiltered(UUID companyId, TransferDocument.Status status, Long courierId);

    @Query("SELECT COALESCE(MAX(CAST(SUBSTRING(td.documentNumber, 14) AS int)), 0) " +
           "FROM TransferDocument td WHERE td.documentNumber LIKE :prefix")
    int findMaxSequenceByPrefix(String prefix);

    @Query(value = "SELECT nextval('transfer_doc_seq')", nativeQuery = true)
    Long getNextTransferDocSequence();
}

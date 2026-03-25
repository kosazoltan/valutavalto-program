package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraTransactionLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface CameraTransactionLinkRepository extends JpaRepository<CameraTransactionLink, UUID> {
    List<CameraTransactionLink> findByReceiptNumber(String receiptNumber);
    List<CameraTransactionLink> findByTransactionId(Long transactionId);
    List<CameraTransactionLink> findByRecordingId(UUID recordingId);
}

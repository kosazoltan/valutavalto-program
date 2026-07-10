package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CameraTransactionLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface CameraTransactionLinkRepository extends JpaRepository<CameraTransactionLink, UUID> {

    /**
     * @deprecated F9 GDPR cross-tenant fix (2026-05-06): a bizonylat-szám több
     * cégnél is létezhet (V&lt;3-jegy iroda&gt;NNNNNN formátum cég-szinten egyedi).
     * Használd a {@link #findByReceiptNumberAndCompanyId} metódust ehelyett.
     */
    @Deprecated(forRemoval = false)
    List<CameraTransactionLink> findByReceiptNumber(String receiptNumber);

    List<CameraTransactionLink> findByTransactionId(Long transactionId);

    List<CameraTransactionLink> findByRecordingId(UUID recordingId);

    @Query("select l from CameraTransactionLink l "
            + "join Branch b on b.id = l.recording.branchId and b.company.id = :companyId "
            + "where l.recording.branchId = :branchId "
            + "and l.transactionTime >= :start and l.transactionTime < :end order by l.transactionTime asc")
    List<CameraTransactionLink> findByBranchAndTimeRange(
            @Param("branchId") UUID branchId,
            @Param("companyId") UUID companyId,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);
}

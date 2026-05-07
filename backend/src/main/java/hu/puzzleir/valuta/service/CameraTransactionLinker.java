package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraTransactionLink;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraTransactionLinkRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@ConditionalOnProperty(name = "camera.enabled", havingValue = "true")
@Service
@RequiredArgsConstructor
@Slf4j
public class CameraTransactionLinker {

    private final CameraRecordingRepository recordingRepository;
    private final CameraTransactionLinkRepository linkRepository;
    private final hu.puzzleir.valuta.repository.TransactionRepository transactionRepository;

    /**
     * Link a transaction to the current camera recording(s).
     * Called when a transaction is created.
     * transaction_id is now BIGINT matching transaction.id.
     */
    @Transactional(rollbackFor = Exception.class)
    public void linkTransaction(Long transactionId, UUID branchId,
                                 LocalDateTime transactionTime, String receiptNumber) {
        if (transactionId == null || branchId == null || transactionTime == null) {
            log.debug("Kamera linkeles kihagyva hianyzo adat miatt: tx={}, branch={}, time={}",
                    transactionId, branchId, transactionTime);
            return;
        }

        // Find active recordings for this branch at the transaction time
        List<CameraRecording> recordings = recordingRepository
                .findByBranchIdAndStartTimeBetween(branchId,
                        transactionTime.minusHours(2), transactionTime.plusMinutes(5));

        // Find recordings that overlap with the transaction time
        for (CameraRecording recording : recordings) {
            LocalDateTime recEnd = recording.getEndTime() != null
                    ? recording.getEndTime()
                    : LocalDateTime.now();

            if (!transactionTime.isBefore(recording.getStartTime()) &&
                !transactionTime.isAfter(recEnd)) {

                int frameOffset = (int) Duration.between(
                        recording.getStartTime(), transactionTime).getSeconds();

                CameraTransactionLink link = CameraTransactionLink.builder()
                        .recording(recording)
                        .transactionId(transactionId)
                        .receiptNumber(receiptNumber)
                        .transactionTime(transactionTime)
                        .frameOffsetSeconds(frameOffset)
                        .build();

                linkRepository.save(link);
                log.info("Tranzakcio linkelve kamerafelvetelhez: tx={}, rec={}, offset={}s",
                        transactionId, recording.getId(), frameOffset);
            }
        }
    }

    /**
     * Find recordings by receipt number.
     *
     * <p>F9 GDPR cross-tenant fix (2026-05-06): a bizonylat-szám több cégnél is
     * létezhet (V&lt;3-jegy iroda&gt;NNNNNN formátum cég-szinten egyedi). Először
     * a cég-szűrt Transaction lookup, aztán a kameralink transactionId alapján.
     * Más cég bizonylatszámához tartozó kameralink NEM jelenhet meg.</p>
     */
    @Transactional(readOnly = true)
    public List<CameraTransactionLink> findByReceiptNumber(String receiptNumber) {
        java.util.UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyIdOrNull();
        if (companyId == null) {
            return List.of();
        }
        return transactionRepository.findByReceiptNumberAndCompanyId(receiptNumber, companyId)
                .map(tx -> linkRepository.findByTransactionId(tx.getId()))
                .orElseGet(List::of);
    }

    /**
     * Find recordings by transaction ID (now Long/BIGINT).
     */
    @Transactional(readOnly = true)
    public List<CameraTransactionLink> findByTransactionId(Long transactionId) {
        return linkRepository.findByTransactionId(transactionId);
    }
}

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
     */
    @Transactional(readOnly = true)
    public List<CameraTransactionLink> findByReceiptNumber(String receiptNumber) {
        return linkRepository.findByReceiptNumber(receiptNumber);
    }

    /**
     * Find recordings by transaction ID (now Long/BIGINT).
     */
    @Transactional(readOnly = true)
    public List<CameraTransactionLink> findByTransactionId(Long transactionId) {
        return linkRepository.findByTransactionId(transactionId);
    }
}

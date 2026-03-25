package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.entity.SyncInboxEvent;
import hu.puzzleir.valuta.entity.SyncOutboxEvent;
import hu.puzzleir.valuta.repository.SyncInboxRepository;
import hu.puzzleir.valuta.repository.SyncOutboxRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;

/**
 * Scheduled outbox dispatcher skeleton.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OutboxSyncWorkerService {

    private static final String RATE_PUBLISHED_EVENT = "RATE_PUBLISHED";
    private static final int MAX_BACKOFF_SECONDS = 900;
    private static final int BATCH_SIZE = 100;

    private final SyncOutboxRepository syncOutboxRepository;
    private final SyncInboxRepository syncInboxRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;

    @Value("${sync.node-id:local-node}")
    private String nodeId;

    @Value("${sync.outbox.max-attempts:12}")
    private int maxAttempts;

    @Value("${sync.outbox.initial-delay-seconds:5}")
    private int initialDelaySeconds;

    @Scheduled(fixedDelayString = "${sync.outbox.fixed-delay-ms:5000}")
    @Transactional(rollbackFor = Exception.class)
    public void dispatchPendingEvents() {
        List<SyncOutboxEvent> pending = syncOutboxRepository.findReadyForDispatch(
                LocalDateTime.now(),
                PageRequest.of(0, BATCH_SIZE)
        );

        if (pending.isEmpty()) {
            return;
        }

        for (SyncOutboxEvent event : pending) {
            processOne(event);
        }
    }

    private void processOne(SyncOutboxEvent event) {
        SyncInboxEvent inboxEvent = getOrCreateInboxEvent(event);
        if (isAlreadyProcessed(inboxEvent)) {
            markAsSent(event);
            return;
        }

        try {
            boolean delivered = sendEvent(event);
            if (delivered) {
                markInboxProcessed(inboxEvent);
                markAsSent(event);
                return;
            }
        } catch (Exception ex) {
            log.warn("Outbox send failed: id={}, eventType={}, error={}",
                    event.getId(), event.getEventType(), ex.getMessage());
        }

        markInboxFailed(inboxEvent);
        scheduleRetry(event);
    }

    protected boolean sendEvent(SyncOutboxEvent event) {
        if (RATE_PUBLISHED_EVENT.equals(event.getEventType())) {
            return dispatchRatePublished(event.getPayload());
        }

        log.warn("Unsupported outbox event type: {}", event.getEventType());
        return false;
    }

    private boolean dispatchRatePublished(String payload) {
        try {
            RateUpdateMessage message = objectMapper.readValue(payload, RateUpdateMessage.class);

            if (message.getWorkgroupId() != null) {
                messagingTemplate.convertAndSend("/topic/rate-updates/" + message.getWorkgroupId(), message);
            }

            if (message.getBranchCodes() != null) {
                for (String branchCode : message.getBranchCodes()) {
                    messagingTemplate.convertAndSend("/topic/rate-updates/branch/" + branchCode, message);
                }
            }

            return true;
        } catch (Exception ex) {
            log.warn("RATE_PUBLISHED dispatch failed: {}", ex.getMessage());
            return false;
        }
    }

    private SyncInboxEvent getOrCreateInboxEvent(SyncOutboxEvent event) {
        return syncInboxRepository.findByIdempotencyKey(event.getIdempotencyKey())
                .orElseGet(() -> syncInboxRepository.save(SyncInboxEvent.builder()
                        .idempotencyKey(event.getIdempotencyKey())
                        .sourceNodeId(nodeId)
                        .eventType(event.getEventType())
                        .payloadHash(sha256(event.getPayload()))
                        .status(SyncInboxEvent.SyncInboxStatus.RECEIVED)
                        .build()));
    }

    private boolean isAlreadyProcessed(SyncInboxEvent inboxEvent) {
        return inboxEvent.getStatus() == SyncInboxEvent.SyncInboxStatus.PROCESSED
                || inboxEvent.getStatus() == SyncInboxEvent.SyncInboxStatus.DUPLICATE;
    }

    private void markInboxProcessed(SyncInboxEvent inboxEvent) {
        inboxEvent.setStatus(SyncInboxEvent.SyncInboxStatus.PROCESSED);
        inboxEvent.setProcessedAt(LocalDateTime.now());
        syncInboxRepository.save(inboxEvent);
    }

    private void markInboxFailed(SyncInboxEvent inboxEvent) {
        inboxEvent.setStatus(SyncInboxEvent.SyncInboxStatus.FAILED);
        syncInboxRepository.save(inboxEvent);
    }

    private String sha256(String payload) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(payload.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 not available", ex);
        }
    }

    private void markAsSent(SyncOutboxEvent event) {
        event.setStatus(SyncOutboxEvent.SyncOutboxStatus.SENT);
        event.setSentAt(LocalDateTime.now());
        event.setNextRetryAt(null);
        syncOutboxRepository.save(event);
    }

    private void scheduleRetry(SyncOutboxEvent event) {
        int attempts = (event.getRetryCount() == null ? 0 : event.getRetryCount()) + 1;
        event.setRetryCount(attempts);

        if (attempts >= maxAttempts) {
            event.setStatus(SyncOutboxEvent.SyncOutboxStatus.DEAD_LETTER);
            event.setNextRetryAt(null);
            syncOutboxRepository.save(event);
            return;
        }

        int multiplier = Math.max(0, attempts - 1);
        int delaySeconds = Math.min(initialDelaySeconds * (1 << Math.min(multiplier, 10)), MAX_BACKOFF_SECONDS);

        event.setStatus(SyncOutboxEvent.SyncOutboxStatus.PENDING);
        event.setNextRetryAt(LocalDateTime.now().plusSeconds(delaySeconds));
        syncOutboxRepository.save(event);
    }
}

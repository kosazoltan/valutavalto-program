package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.dto.sync.SyncInboundEventRequest;
import hu.puzzleir.valuta.dto.sync.SyncInboundEventResponse;
import hu.puzzleir.valuta.entity.SyncInboxEvent;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SyncInboxRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Objects;

@Service
@RequiredArgsConstructor
@Slf4j
public class SyncInboundEventService {

    private static final String RATE_PUBLISHED_EVENT = "RATE_PUBLISHED";

    private final SyncInboxRepository syncInboxRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper;

    @Transactional
    public SyncInboundEventResponse receive(String idempotencyKey, SyncInboundEventRequest request) {
        if (!StringUtils.hasText(idempotencyKey)) {
            throw new ValidationException("Hiányzó Idempotency-Key header");
        }

        String canonicalPayload = serializePayload(request);
        String payloadHash = sha256(canonicalPayload);

        SyncInboxEvent inboxEvent = syncInboxRepository.findByIdempotencyKey(idempotencyKey)
                .orElse(null);

        if (inboxEvent != null) {
            return handleExistingEvent(inboxEvent, idempotencyKey, request, canonicalPayload, payloadHash);
        }

        SyncInboxEvent created = syncInboxRepository.save(SyncInboxEvent.builder()
                .idempotencyKey(idempotencyKey)
                .sourceNodeId(request.getSourceNodeId())
                .eventType(request.getEventType())
                .payloadHash(payloadHash)
                .status(SyncInboxEvent.SyncInboxStatus.RECEIVED)
                .build());

        return processAndBuildResponse(created, idempotencyKey, request.getEventType(), canonicalPayload, false);
    }

    private SyncInboundEventResponse handleExistingEvent(SyncInboxEvent existing,
                                                         String idempotencyKey,
                                                         SyncInboundEventRequest request,
                                                         String canonicalPayload,
                                                         String incomingPayloadHash) {

        if (!Objects.equals(existing.getPayloadHash(), incomingPayloadHash)) {
            existing.setStatus(SyncInboxEvent.SyncInboxStatus.FAILED);
            syncInboxRepository.save(existing);
            throw new BusinessException(
                    "Idempotency ütközés: azonos kulcshoz eltérő payload érkezett",
                    "SYNC_PAYLOAD_CONFLICT",
                    HttpStatus.CONFLICT
            );
        }

        if (existing.getStatus() == SyncInboxEvent.SyncInboxStatus.PROCESSED
                || existing.getStatus() == SyncInboxEvent.SyncInboxStatus.DUPLICATE) {
            existing.setStatus(SyncInboxEvent.SyncInboxStatus.DUPLICATE);
            existing.setProcessedAt(LocalDateTime.now());
            SyncInboxEvent saved = syncInboxRepository.save(existing);

            return SyncInboundEventResponse.builder()
                    .idempotencyKey(idempotencyKey)
                    .eventType(saved.getEventType())
                    .status(saved.getStatus().name())
                    .duplicate(true)
                    .processedAt(saved.getProcessedAt())
                    .message("Duplikált esemény, újrafeldolgozás kihagyva")
                    .build();
        }

        existing.setSourceNodeId(request.getSourceNodeId());
        existing.setEventType(request.getEventType());
        existing.setPayloadHash(incomingPayloadHash);
        syncInboxRepository.save(existing);

        return processAndBuildResponse(existing, idempotencyKey, request.getEventType(), canonicalPayload, false);
    }

    private SyncInboundEventResponse processAndBuildResponse(SyncInboxEvent inboxEvent,
                                                             String idempotencyKey,
                                                             String eventType,
                                                             String canonicalPayload,
                                                             boolean duplicate) {
        try {
            dispatch(eventType, canonicalPayload);
            inboxEvent.setStatus(SyncInboxEvent.SyncInboxStatus.PROCESSED);
            inboxEvent.setProcessedAt(LocalDateTime.now());
            SyncInboxEvent saved = syncInboxRepository.save(inboxEvent);

            return SyncInboundEventResponse.builder()
                    .idempotencyKey(idempotencyKey)
                    .eventType(eventType)
                    .status(saved.getStatus().name())
                    .duplicate(duplicate)
                    .processedAt(saved.getProcessedAt())
                    .message("Esemény feldolgozva")
                    .build();
        } catch (ValidationException ex) {
            inboxEvent.setStatus(SyncInboxEvent.SyncInboxStatus.FAILED);
            syncInboxRepository.save(inboxEvent);
            throw ex;
        } catch (Exception ex) {
            inboxEvent.setStatus(SyncInboxEvent.SyncInboxStatus.FAILED);
            syncInboxRepository.save(inboxEvent);
            log.warn("Inbound sync event processing failed: eventType={}, error={}", eventType, ex.getMessage());
            throw new BusinessException(
                    "Inbound sync esemény feldolgozása sikertelen",
                    "SYNC_EVENT_PROCESSING_FAILED",
                    HttpStatus.UNPROCESSABLE_ENTITY
            );
        }
    }

    private void dispatch(String eventType, String payload) throws JsonProcessingException {
        if (!RATE_PUBLISHED_EVENT.equals(eventType)) {
            throw new ValidationException("Nem támogatott sync esemény típus: " + eventType);
        }

        RateUpdateMessage message = objectMapper.readValue(payload, RateUpdateMessage.class);

        if (message.getWorkgroupId() != null) {
            messagingTemplate.convertAndSend("/topic/rate-updates/" + message.getWorkgroupId(), message);
        }

        if (message.getBranchCodes() != null) {
            for (String branchCode : message.getBranchCodes()) {
                messagingTemplate.convertAndSend("/topic/rate-updates/branch/" + branchCode, message);
            }
        }
    }

    private String serializePayload(SyncInboundEventRequest request) {
        try {
            return objectMapper.writeValueAsString(request.getPayload());
        } catch (JsonProcessingException ex) {
            throw new ValidationException("Érvénytelen payload JSON: " + ex.getMessage());
        }
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
}

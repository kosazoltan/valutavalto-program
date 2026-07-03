package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.dto.sync.SyncInboundEventRequest;
import hu.puzzleir.valuta.dto.sync.SyncInboundEventResponse;
import hu.puzzleir.valuta.entity.SyncInboxEvent;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.SyncInboxRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SyncInboundEventServiceTest {

    @Mock
    private SyncInboxRepository syncInboxRepository;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    private SyncInboundEventService service;

    @BeforeEach
    void setUp() {
        ObjectMapper objectMapper = new ObjectMapper();
        service = new SyncInboundEventService(syncInboxRepository, messagingTemplate, objectMapper);

        when(syncInboxRepository.save(any(SyncInboxEvent.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    @DisplayName("receive processes new RATE_PUBLISHED event")
    void processesNewRatePublishedEvent() throws Exception {
        String idempotencyKey = UUID.randomUUID().toString();
        when(syncInboxRepository.findByIdempotencyKey(idempotencyKey))
                .thenReturn(Optional.empty());

        SyncInboundEventRequest request = SyncInboundEventRequest.builder()
                .sourceNodeId("edge-1")
                .eventType("RATE_PUBLISHED")
                .payload(new ObjectMapper().readTree("{\"workgroupId\":\"f9c218ce-5f79-4a67-87aa-8f0e9e978cf4\",\"branchCodes\":[\"BORSI\"],\"publishedAt\":\"2026-03-14T12:00:00\",\"rates\":[]}"))
                .build();

        SyncInboundEventResponse response = service.receive(idempotencyKey, request);

        assertEquals("PROCESSED", response.getStatus());
        assertFalse(response.isDuplicate());
        assertNotNull(response.getProcessedAt());

        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/rate-updates/f9c218ce-5f79-4a67-87aa-8f0e9e978cf4"), any(RateUpdateMessage.class));
        verify(messagingTemplate, times(1))
                .convertAndSend(eq("/topic/rate-updates/branch/BORSI"), any(RateUpdateMessage.class));
    }

    @Test
    @DisplayName("receive returns duplicate when same hash already processed")
    void returnsDuplicateWhenAlreadyProcessed() throws Exception {
        String idempotencyKey = UUID.randomUUID().toString();
        String payload = "{\"workgroupId\":\"f9c218ce-5f79-4a67-87aa-8f0e9e978cf4\",\"branchCodes\":[],\"publishedAt\":\"2026-03-14T12:00:00\",\"rates\":[]}";

        ObjectMapper mapper = new ObjectMapper();
        String hash = sha256(mapper.writeValueAsString(mapper.readTree(payload)));

        when(syncInboxRepository.findByIdempotencyKey(idempotencyKey))
                .thenReturn(Optional.of(SyncInboxEvent.builder()
                        .id(UUID.randomUUID())
                        .idempotencyKey(idempotencyKey)
                        .sourceNodeId("edge-1")
                        .eventType("RATE_PUBLISHED")
                        .payloadHash(hash)
                        .status(SyncInboxEvent.SyncInboxStatus.PROCESSED)
                        .processedAt(LocalDateTime.now())
                        .build()));

        SyncInboundEventRequest request = SyncInboundEventRequest.builder()
                .sourceNodeId("edge-1")
                .eventType("RATE_PUBLISHED")
                .payload(mapper.readTree(payload))
                .build();

        SyncInboundEventResponse response = service.receive(idempotencyKey, request);

        assertTrue(response.isDuplicate());
        assertEquals("DUPLICATE", response.getStatus());
                verifyNoInteractions(messagingTemplate);
    }

    @Test
    @DisplayName("receive marks FAILED and throws conflict on payload hash mismatch")
    void throwsConflictWhenPayloadHashMismatch() throws Exception {
        String idempotencyKey = UUID.randomUUID().toString();

        when(syncInboxRepository.findByIdempotencyKey(idempotencyKey))
                .thenReturn(Optional.of(SyncInboxEvent.builder()
                        .id(UUID.randomUUID())
                        .idempotencyKey(idempotencyKey)
                        .sourceNodeId("edge-1")
                        .eventType("RATE_PUBLISHED")
                        .payloadHash("different-hash")
                        .status(SyncInboxEvent.SyncInboxStatus.PROCESSED)
                        .build()));

        SyncInboundEventRequest request = SyncInboundEventRequest.builder()
                .sourceNodeId("edge-2")
                .eventType("RATE_PUBLISHED")
                .payload(new ObjectMapper().readTree("{\"workgroupId\":\"f9c218ce-5f79-4a67-87aa-8f0e9e978cf4\",\"branchCodes\":[],\"publishedAt\":\"2026-03-14T12:00:00\",\"rates\":[]}"))
                .build();

        BusinessException ex = assertThrows(BusinessException.class, () -> service.receive(idempotencyKey, request));
        assertEquals(HttpStatus.CONFLICT, ex.getHttpStatus());
        assertEquals("SYNC_PAYLOAD_CONFLICT", ex.getErrorCode());

        ArgumentCaptor<SyncInboxEvent> captor = ArgumentCaptor.forClass(SyncInboxEvent.class);
        verify(syncInboxRepository, times(1)).save(captor.capture());
        assertEquals(SyncInboxEvent.SyncInboxStatus.FAILED, captor.getValue().getStatus());
    }

    private String sha256(String payload) throws Exception {
        java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
        byte[] hash = digest.digest(payload.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        return java.util.HexFormat.of().formatHex(hash);
    }
}

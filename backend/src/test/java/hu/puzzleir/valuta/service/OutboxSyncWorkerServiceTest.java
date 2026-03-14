package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratemanagement.RateUpdateMessage;
import hu.puzzleir.valuta.entity.SyncInboxEvent;
import hu.puzzleir.valuta.entity.SyncOutboxEvent;
import hu.puzzleir.valuta.repository.SyncInboxRepository;
import hu.puzzleir.valuta.repository.SyncOutboxRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.data.domain.Pageable;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OutboxSyncWorkerServiceTest {

    @Mock
    private SyncOutboxRepository syncOutboxRepository;

    @Mock
    private SyncInboxRepository syncInboxRepository;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    private OutboxSyncWorkerService service;

    @BeforeEach
    void setUp() {
        ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();
        service = spy(new OutboxSyncWorkerService(
                syncOutboxRepository,
                syncInboxRepository,
                messagingTemplate,
            objectMapper
        ));

        ReflectionTestUtils.setField(service, "maxAttempts", 3);
        ReflectionTestUtils.setField(service, "initialDelaySeconds", 5);
        ReflectionTestUtils.setField(service, "nodeId", "test-node");

        when(syncOutboxRepository.save(any(SyncOutboxEvent.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        when(syncInboxRepository.findByIdempotencyKey(anyString()))
                .thenReturn(Optional.empty());

        lenient().when(syncInboxRepository.save(any(SyncInboxEvent.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    @DisplayName("dispatchPendingEvents marks successful event as SENT")
    void marksSuccessfulEventAsSent() {
        SyncOutboxEvent event = baseEvent("RATE_PUBLISHED", 0);
        when(syncOutboxRepository.findReadyForDispatch(any(LocalDateTime.class), any(Pageable.class)))
                .thenReturn(List.of(event));
        doReturn(true).when(service).sendEvent(any(SyncOutboxEvent.class));

        service.dispatchPendingEvents();

        ArgumentCaptor<SyncOutboxEvent> savedCaptor = ArgumentCaptor.forClass(SyncOutboxEvent.class);
        verify(syncOutboxRepository, times(1)).save(savedCaptor.capture());
        SyncOutboxEvent saved = savedCaptor.getValue();

        assertEquals(SyncOutboxEvent.SyncOutboxStatus.SENT, saved.getStatus());
        assertNotNull(saved.getSentAt());
        assertNull(saved.getNextRetryAt());
    }

    @Test
    @DisplayName("dispatchPendingEvents schedules retry on failure")
    void schedulesRetryOnFailure() {
        SyncOutboxEvent event = baseEvent("FORCE_FAIL", 0);
        when(syncOutboxRepository.findReadyForDispatch(any(LocalDateTime.class), any(Pageable.class)))
                .thenReturn(List.of(event));
        doReturn(false).when(service).sendEvent(any(SyncOutboxEvent.class));

        service.dispatchPendingEvents();

        ArgumentCaptor<SyncOutboxEvent> savedCaptor = ArgumentCaptor.forClass(SyncOutboxEvent.class);
        verify(syncOutboxRepository, times(1)).save(savedCaptor.capture());
        SyncOutboxEvent saved = savedCaptor.getValue();

        assertEquals(SyncOutboxEvent.SyncOutboxStatus.PENDING, saved.getStatus());
        assertEquals(1, saved.getRetryCount());
        assertNotNull(saved.getNextRetryAt());
    }

    @Test
    @DisplayName("dispatchPendingEvents sends failed event to dead-letter after max attempts")
    void movesToDeadLetterAfterMaxAttempts() {
        SyncOutboxEvent event = baseEvent("FORCE_FAIL", 2);
        when(syncOutboxRepository.findReadyForDispatch(any(LocalDateTime.class), any(Pageable.class)))
                .thenReturn(List.of(event));
        doReturn(false).when(service).sendEvent(any(SyncOutboxEvent.class));

        service.dispatchPendingEvents();

        ArgumentCaptor<SyncOutboxEvent> savedCaptor = ArgumentCaptor.forClass(SyncOutboxEvent.class);
        verify(syncOutboxRepository, times(1)).save(savedCaptor.capture());
        SyncOutboxEvent saved = savedCaptor.getValue();

        assertEquals(SyncOutboxEvent.SyncOutboxStatus.DEAD_LETTER, saved.getStatus());
        assertEquals(3, saved.getRetryCount());
        assertNull(saved.getNextRetryAt());
    }

        @Test
        @DisplayName("dispatchPendingEvents skips transport when inbox already processed")
        void skipsTransportWhenInboxAlreadyProcessed() {
        SyncOutboxEvent event = baseEvent("RATE_PUBLISHED", 0);
        when(syncOutboxRepository.findReadyForDispatch(any(LocalDateTime.class), any(Pageable.class)))
            .thenReturn(List.of(event));
        when(syncInboxRepository.findByIdempotencyKey(anyString()))
            .thenReturn(Optional.of(SyncInboxEvent.builder()
                .id(UUID.randomUUID())
                .idempotencyKey(event.getIdempotencyKey())
                .sourceNodeId("edge-1")
                .eventType(event.getEventType())
                .payloadHash("hash")
                .status(SyncInboxEvent.SyncInboxStatus.PROCESSED)
                .build()));

        service.dispatchPendingEvents();

        verify(service, never()).sendEvent(any(SyncOutboxEvent.class));
        ArgumentCaptor<SyncOutboxEvent> savedCaptor = ArgumentCaptor.forClass(SyncOutboxEvent.class);
        verify(syncOutboxRepository, times(1)).save(savedCaptor.capture());
        assertEquals(SyncOutboxEvent.SyncOutboxStatus.SENT, savedCaptor.getValue().getStatus());
        }

        @Test
        @DisplayName("dispatchPendingEvents sends RATE_PUBLISHED to workgroup and branch topics")
        void dispatchesRatePublishedToTopics() {
        UUID workgroupId = UUID.randomUUID();
        SyncOutboxEvent event = baseEvent("RATE_PUBLISHED", 0);
        event.setPayload("{\"workgroupId\":\"" + workgroupId + "\",\"branchCodes\":[\"BORSI\",\"PEST\"],\"publishedAt\":\"2026-03-14T10:15:30\",\"rates\":[]}");

        when(syncOutboxRepository.findReadyForDispatch(any(LocalDateTime.class), any(Pageable.class)))
            .thenReturn(List.of(event));

        service.dispatchPendingEvents();

        verify(messagingTemplate, times(1))
            .convertAndSend(eq("/topic/rate-updates/" + workgroupId), any(RateUpdateMessage.class));
        verify(messagingTemplate, times(1))
            .convertAndSend(eq("/topic/rate-updates/branch/BORSI"), any(RateUpdateMessage.class));
        verify(messagingTemplate, times(1))
            .convertAndSend(eq("/topic/rate-updates/branch/PEST"), any(RateUpdateMessage.class));
        }

    private SyncOutboxEvent baseEvent(String eventType, int retryCount) {
        return SyncOutboxEvent.builder()
                .id(UUID.randomUUID())
                .aggregateType("RATE_PUBLICATION")
                .aggregateId(UUID.randomUUID().toString())
                .eventType(eventType)
                .idempotencyKey(UUID.randomUUID().toString())
                .payload("{}")
                .status(SyncOutboxEvent.SyncOutboxStatus.PENDING)
                .retryCount(retryCount)
                .createdAt(LocalDateTime.now())
                .build();
    }
}

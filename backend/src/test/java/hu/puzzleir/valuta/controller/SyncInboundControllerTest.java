package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.sync.SyncInboundEventRequest;
import hu.puzzleir.valuta.dto.sync.SyncInboundEventResponse;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.GlobalExceptionHandler;
import hu.puzzleir.valuta.service.SyncInboundEventService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class SyncInboundControllerTest {

    private MockMvc mockMvc;

    @Mock
    private SyncInboundEventService syncInboundEventService;

    @InjectMocks
    private SyncInboundController controller;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    @DisplayName("POST /sync/events returns 200 on valid request")
    void receiveEvent_returnsOk() throws Exception {
        String idempotencyKey = UUID.randomUUID().toString();

        SyncInboundEventResponse response = SyncInboundEventResponse.builder()
                .idempotencyKey(idempotencyKey)
                .eventType("RATE_PUBLISHED")
                .status("PROCESSED")
                .duplicate(false)
                .processedAt(LocalDateTime.now())
                .message("Esemeny feldolgozva")
                .build();

        when(syncInboundEventService.receive(eq(idempotencyKey), any(SyncInboundEventRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/v1/sync/events")
                        .header("Idempotency-Key", idempotencyKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validRequestBody()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idempotencyKey").value(idempotencyKey))
                .andExpect(jsonPath("$.eventType").value("RATE_PUBLISHED"))
                .andExpect(jsonPath("$.status").value("PROCESSED"))
                .andExpect(jsonPath("$.duplicate").value(false));

        verify(syncInboundEventService, times(1)).receive(eq(idempotencyKey), any(SyncInboundEventRequest.class));
    }

    @Test
    @DisplayName("POST /sync/events returns 400 when Idempotency-Key header is missing")
    void receiveEvent_missingIdempotencyHeader_returnsBadRequest() throws Exception {
        mockMvc.perform(post("/api/v1/sync/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validRequestBody()))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(syncInboundEventService);
    }

    @Test
    @DisplayName("POST /sync/events returns 409 on payload conflict")
    void receiveEvent_payloadConflict_returnsConflict() throws Exception {
        String idempotencyKey = UUID.randomUUID().toString();

        when(syncInboundEventService.receive(eq(idempotencyKey), any(SyncInboundEventRequest.class)))
                .thenThrow(new BusinessException(
                        "Idempotency utkozes",
                        "SYNC_PAYLOAD_CONFLICT",
                        HttpStatus.CONFLICT
                ));

        mockMvc.perform(post("/api/v1/sync/events")
                        .header("Idempotency-Key", idempotencyKey)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validRequestBody()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("SYNC_PAYLOAD_CONFLICT"));

        verify(syncInboundEventService, times(1)).receive(eq(idempotencyKey), any(SyncInboundEventRequest.class));
    }

    private String validRequestBody() {
        return """
                {
                  "sourceNodeId": "edge-1",
                  "eventType": "RATE_PUBLISHED",
                  "payload": {
                    "workgroupId": "f9c218ce-5f79-4a67-87aa-8f0e9e978cf4",
                    "branchCodes": ["BORSI"],
                    "publishedAt": "2026-03-14T12:00:00",
                    "rates": []
                  }
                }
                """;
    }
}
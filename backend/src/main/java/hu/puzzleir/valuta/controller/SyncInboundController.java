package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.sync.SyncInboundEventRequest;
import hu.puzzleir.valuta.dto.sync.SyncInboundEventResponse;
import hu.puzzleir.valuta.service.SyncInboundEventService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/sync/events")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class SyncInboundController {

    private final SyncInboundEventService syncInboundEventService;

    @PostMapping
    public ResponseEntity<SyncInboundEventResponse> receiveEvent(
            @RequestHeader("Idempotency-Key") String idempotencyKey,
            @Valid @RequestBody SyncInboundEventRequest request
    ) {
        return ResponseEntity.ok(syncInboundEventService.receive(idempotencyKey, request));
    }
}

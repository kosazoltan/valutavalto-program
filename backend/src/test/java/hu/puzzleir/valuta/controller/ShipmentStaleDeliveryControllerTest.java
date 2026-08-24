package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.shipment.ShipmentDeliverRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.service.ShipmentVatSupplyService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentStaleDeliveryControllerTest {

    @Mock private ShipmentService shipmentService;
    @Mock private ShipmentHandlingFeeService handlingFeeService;
    @Mock private ShipmentVatSupplyService vatSupplyService;
    @Mock private IdempotencyGuard idempotencyGuard;

    private ShipmentController controller;

    @BeforeEach
    void setUp() {
        controller = new ShipmentController(
                shipmentService, handlingFeeService, vatSupplyService, idempotencyGuard);
    }

    @Test
    void nullBodyRemainsBackwardCompatibleAndDelegatesUnconfirmed() {
        UUID id = UUID.randomUUID();
        String key = UUID.randomUUID().toString();
        ShipmentRequestResponseDto dto = ShipmentRequestResponseDto.builder().id(id).build();
        IdempotencyGuard.Acquired<ShipmentRequestResponseDto> acquired =
                new IdempotencyGuard.Acquired<>(null, null, ShipmentRequestResponseDto.class);
        when(idempotencyGuard.tryAcquire(eq(key), eq("POST /api/v1/shipments/" + id + "/deliver"),
                eq(id), eq(ShipmentRequestResponseDto.class))).thenReturn(acquired);
        when(shipmentService.deliverResponse(id, false)).thenReturn(dto);

        ResponseEntity<ShipmentRequestResponseDto> response = controller.deliver(id, key, null, null);

        assertThat(response.getBody()).isSameAs(dto);
        verify(shipmentService).deliverResponse(id, false);
        verify(idempotencyGuard).complete(acquired, dto);
    }

    @Test
    void confirmedStaleBodyPropagatesToService() {
        UUID id = UUID.randomUUID();
        String key = UUID.randomUUID().toString();
        ShipmentDeliverRequest body = new ShipmentDeliverRequest(true);
        ShipmentRequestResponseDto dto = ShipmentRequestResponseDto.builder().id(id).build();
        IdempotencyGuard.Acquired<ShipmentRequestResponseDto> acquired =
                new IdempotencyGuard.Acquired<>(null, null, ShipmentRequestResponseDto.class);
        when(idempotencyGuard.tryAcquire(eq(key), eq("POST /api/v1/shipments/" + id + "/deliver"),
                eq(id), eq(ShipmentRequestResponseDto.class))).thenReturn(acquired);
        when(shipmentService.deliverResponse(id, true)).thenReturn(dto);

        controller.deliver(id, key, null, body);

        verify(shipmentService).deliverResponse(id, true);
    }

    @Test
    void emptyJsonBodyRemainsEquivalentToLegacyUnconfirmedCall() {
        UUID id = UUID.randomUUID();
        String key = UUID.randomUUID().toString();
        ShipmentRequestResponseDto dto = ShipmentRequestResponseDto.builder().id(id).build();
        IdempotencyGuard.Acquired<ShipmentRequestResponseDto> acquired =
                new IdempotencyGuard.Acquired<>(null, null, ShipmentRequestResponseDto.class);
        when(idempotencyGuard.tryAcquire(eq(key), eq("POST /api/v1/shipments/" + id + "/deliver"),
                eq(id), eq(ShipmentRequestResponseDto.class))).thenReturn(acquired);
        when(shipmentService.deliverResponse(id, false)).thenReturn(dto);

        controller.deliver(id, key, null, new ShipmentDeliverRequest());

        verify(shipmentService).deliverResponse(id, false);
    }

    @Test
    void cachedReplayDoesNotInvokeServiceAgainEvenWithConfirmedBody() {
        UUID id = UUID.randomUUID();
        String key = UUID.randomUUID().toString();
        ShipmentRequestResponseDto cached = ShipmentRequestResponseDto.builder().id(id).build();
        IdempotencyGuard.Acquired<ShipmentRequestResponseDto> acquired =
                new IdempotencyGuard.Acquired<>(null, cached, ShipmentRequestResponseDto.class);
        when(idempotencyGuard.tryAcquire(eq(key), eq("POST /api/v1/shipments/" + id + "/deliver"),
                eq(id), eq(ShipmentRequestResponseDto.class))).thenReturn(acquired);

        ResponseEntity<ShipmentRequestResponseDto> response =
                controller.deliver(id, key, null, new ShipmentDeliverRequest(true));

        assertThat(response.getBody()).isSameAs(cached);
        verify(shipmentService, never()).deliverResponse(id, true);
    }

    @Test
    void optionalBodyIsPartOfRuntimeControllerContract() throws Exception {
        var bodyParameter = ShipmentController.class
                .getDeclaredMethod(
                        "deliver", UUID.class, String.class, String.class, ShipmentDeliverRequest.class)
                .getParameters()[3];

        assertThat(bodyParameter.getAnnotation(RequestBody.class)).isNotNull();
        assertThat(bodyParameter.getAnnotation(RequestBody.class).required()).isFalse();
    }
}

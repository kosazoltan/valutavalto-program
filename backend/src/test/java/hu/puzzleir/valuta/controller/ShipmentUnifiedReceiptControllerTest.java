package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.shipment.ShipmentDeliverRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.service.ShipmentVatSupplyService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import io.swagger.v3.oas.annotations.responses.ApiResponses;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RequestHeader;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentUnifiedReceiptControllerTest {

    private static final String FULL_SHIPMENT_ROLE_AUTHORIZATION =
            "hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', "
                    + "'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')";
    private static final String DEPRECATED_WRITE_ROLE_AUTHORIZATION =
            "hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')";

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
    void pendingDelegatesToCurrentBranchScopedService() {
        ShipmentRequestResponseDto dto = ShipmentRequestResponseDto.builder().id(UUID.randomUUID()).build();
        when(shipmentService.findPendingForCurrentBranchResponse()).thenReturn(List.of(dto));

        assertThat(controller.pending().getBody()).containsExactly(dto);
    }

    @Test
    void pendingHasExplicitReceiverRoleAuthorization() throws Exception {
        PreAuthorize authorization = ShipmentController.class.getDeclaredMethod("pending")
                .getAnnotation(PreAuthorize.class);

        assertThat(authorization).isNotNull();
        assertThat(authorization.value())
                .contains("'PENZTAR'")
                .contains("'ERTEKTAR'")
                .contains("'FOERTEKTAR'");
    }

    @Test
    void submitAndCancelHaveExplicitFullRoleAuthorizationContract() throws Exception {
        PreAuthorize submitAuthorization = ShipmentController.class
                .getDeclaredMethod("submit", UUID.class)
                .getAnnotation(PreAuthorize.class);
        PreAuthorize cancelAuthorization = ShipmentController.class
                .getDeclaredMethod("cancel", UUID.class)
                .getAnnotation(PreAuthorize.class);

        assertThat(submitAuthorization).isNotNull();
        assertThat(submitAuthorization.value()).isEqualTo(FULL_SHIPMENT_ROLE_AUTHORIZATION);
        assertThat(cancelAuthorization).isNotNull();
        assertThat(cancelAuthorization.value()).isEqualTo(FULL_SHIPMENT_ROLE_AUTHORIZATION);
    }

    @Test
    void deprecatedApproveAndRejectHaveSameNarrowWriteRoleAuthorizationContract() throws Exception {
        PreAuthorize approveAuthorization = ShipmentController.class
                .getDeclaredMethod("approve", UUID.class)
                .getAnnotation(PreAuthorize.class);
        PreAuthorize rejectAuthorization = ShipmentController.class
                .getDeclaredMethod("reject", UUID.class, String.class)
                .getAnnotation(PreAuthorize.class);

        assertThat(approveAuthorization).isNotNull();
        assertThat(rejectAuthorization).isNotNull();
        assertThat(approveAuthorization.value()).isEqualTo(DEPRECATED_WRITE_ROLE_AUTHORIZATION);
        assertThat(rejectAuthorization.value()).isEqualTo(approveAuthorization.value());
        assertThat(rejectAuthorization.value())
                .contains("'ERTEKTAR'")
                .doesNotContain("'PENZTAR'", "'CASHIER'");
    }

    @Test
    void deliverUsesStableHeaderKeyAndCompletesIdempotencyRecord() {
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
        verify(idempotencyGuard).complete(acquired, dto);
    }

    @Test
    void deliverReturnsCachedIdempotentResponseWithoutSecondMutation() {
        UUID id = UUID.randomUUID();
        String key = UUID.randomUUID().toString();
        ShipmentRequestResponseDto cached = ShipmentRequestResponseDto.builder().id(id).build();
        IdempotencyGuard.Acquired<ShipmentRequestResponseDto> acquired =
                new IdempotencyGuard.Acquired<>(null, cached, ShipmentRequestResponseDto.class);
        when(idempotencyGuard.tryAcquire(eq(key), eq("POST /api/v1/shipments/" + id + "/deliver"),
                eq(id), eq(ShipmentRequestResponseDto.class))).thenReturn(acquired);

        ResponseEntity<ShipmentRequestResponseDto> response = controller.deliver(id, null, key, null);

        assertThat(response.getBody()).isSameAs(cached);
        verify(shipmentService, never()).deliverResponse(id, false);
        verify(idempotencyGuard, never()).complete(acquired, cached);
    }

    @Test
    void deliverPublishesBothIdempotencyHeadersInTheRuntimeContract() throws Exception {
        var parameters = ShipmentController.class
                .getDeclaredMethod(
                        "deliver", UUID.class, String.class, String.class, ShipmentDeliverRequest.class)
                .getParameters();

        assertThat(parameters[1].getAnnotation(RequestHeader.class).name())
                .isEqualTo("Idempotency-Key");
        assertThat(parameters[2].getAnnotation(RequestHeader.class).name())
                .isEqualTo("X-Idempotency-Key");
        assertThat(parameters[1].getAnnotation(RequestHeader.class).required()).isFalse();
        assertThat(parameters[2].getAnnotation(RequestHeader.class).required()).isFalse();
    }

    @Test
    void deliverPublishesConflictResponseForOfflineVerification() throws Exception {
        ApiResponses responses = ShipmentController.class
                .getDeclaredMethod(
                        "deliver", UUID.class, String.class, String.class, ShipmentDeliverRequest.class)
                .getAnnotation(ApiResponses.class);

        assertThat(responses).isNotNull();
        assertThat(responses.value())
                .extracting(response -> response.responseCode())
                .contains("200", "409");
    }

    @Test
    void deprecatedApproveAndRejectExposeMigrationHeaders() {
        UUID id = UUID.randomUUID();
        when(shipmentService.approveResponse(id)).thenReturn(mock(ShipmentRequestResponseDto.class));
        when(shipmentService.rejectResponse(id, "hiba")).thenReturn(mock(ShipmentRequestResponseDto.class));

        ResponseEntity<ShipmentRequestResponseDto> approve = controller.approve(id);
        ResponseEntity<ShipmentRequestResponseDto> reject = controller.reject(id, "hiba");

        assertThat(approve.getHeaders().getFirst("Deprecation")).isEqualTo("true");
        assertThat(reject.getHeaders().getFirst("Deprecation")).isEqualTo("true");
        assertThat(approve.getHeaders().getFirst("Sunset")).isNotBlank();
        assertThat(reject.getHeaders().getFirst("Sunset")).isNotBlank();
    }
}

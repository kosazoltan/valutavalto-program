package hu.puzzleir.valuta.service;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.LoggerFactory;
import tools.jackson.databind.ObjectMapper;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentServiceStaleDeliveryTest {

    @Mock private ShipmentRequestRepository repository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private ShipmentStockBookingService stockBookingService;
    @Mock private ShipmentHandlingFeeSyncService handlingFeeSyncService;
    @Mock private ShipmentVatSupplySyncService vatSupplySyncService;
    @Mock private AccessScopeService accessScopeService;
    @Mock private AuditLogService auditLogService;
    @Mock private SystemParameterService systemParameterService;

    @InjectMocks private ShipmentService service;

    private Logger shipmentLogger;
    private Level previousLogLevel;
    private ListAppender<ILoggingEvent> logAppender;

    @BeforeEach
    void setUp() {
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        lenient().when(systemParameterService.getRawValue(
                ShipmentService.PARAM_STALE_WARNING_HOURS,
                null))
                .thenReturn(String.valueOf(ShipmentService.DEFAULT_STALE_HOURS));
        shipmentLogger = (Logger) LoggerFactory.getLogger(ShipmentService.class);
        previousLogLevel = shipmentLogger.getLevel();
        shipmentLogger.setLevel(Level.WARN);
        logAppender = new ListAppender<>();
        logAppender.start();
        shipmentLogger.addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        shipmentLogger.detachAppender(logAppender);
        logAppender.stop();
        shipmentLogger.setLevel(previousLogLevel);
    }

    @Test
    void confirmedStaleDeliverWritesConfirmationAuditExactlyOnce() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, LocalDateTime.now().minusHours(49), ShipmentRequestStatus.SUBMITTED);
        stubDeliver(request, companyId);

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            ShipmentRequest delivered = service.deliver(shipmentId, true);
            assertThat(delivered.getStatus()).isEqualTo(ShipmentRequestStatus.DELIVERED);
        }

        verify(auditLogService, times(1)).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                eq("ShipmentRequest"),
                eq(shipmentId.toString()),
                eq("77"),
                isNull(),
                eq(request.getToBranchId().toString()),
                isNull(),
                org.mockito.ArgumentMatchers.argThat((String changes) ->
                        changes.contains("\"KAT\":\"TX\"")
                                && changes.contains("\"shipment_request_id\":\"" + shipmentId + "\"")
                                && changes.contains("\"request_number\":\"FF-000123\"")
                                && changes.contains("\"threshold_hours\":48")
                                && changes.contains("\"confirmed\":true")),
                isNull(),
                isNull());
    }

    @Test
    void confirmedStaleAuditSerializesQuotedAndControlCharacterRequestNumberAsValidJson() throws Exception {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, LocalDateTime.now().minusHours(49), ShipmentRequestStatus.SUBMITTED);
        String requestNumber = "FF-\"quoted\"\ncontrol\t\u0001";
        request.setRequestNumber(requestNumber);
        stubDeliver(request, companyId);

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            service.deliver(shipmentId, true);
        }

        ArgumentCaptor<String> changesCaptor = ArgumentCaptor.forClass(String.class);
        verify(auditLogService).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                eq("ShipmentRequest"),
                eq(shipmentId.toString()),
                eq("77"),
                isNull(),
                eq(request.getToBranchId().toString()),
                isNull(),
                changesCaptor.capture(),
                isNull(),
                isNull());
        Map<?, ?> changes = new ObjectMapper().readValue(changesCaptor.getValue(), Map.class);
        assertThat(changes.get("request_number")).isEqualTo(requestNumber);
        assertThat(changes.get("confirmed")).isEqualTo(true);
    }

    @Test
    void staleDeliverWithoutConfirmationRemainsBackwardCompatibleAndDoesNotAuditConfirmation() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, LocalDateTime.now().minusHours(49), ShipmentRequestStatus.APPROVED);
        stubDeliver(request, companyId);

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            assertThat(service.deliver(shipmentId).getStatus()).isEqualTo(ShipmentRequestStatus.DELIVERED);
        }

        verify(auditLogService, never()).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void freshDeliverIgnoresFalseClientStaleClaimAndDoesNotAuditConfirmation() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, LocalDateTime.now().minusHours(1), ShipmentRequestStatus.IN_TRANSIT);
        stubDeliver(request, companyId);

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            assertThat(service.deliver(shipmentId, true).getStatus()).isEqualTo(ShipmentRequestStatus.DELIVERED);
        }

        verify(auditLogService, never()).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void exactThresholdIsNotStaleButOneMinuteBeyondIsStale() {
        LocalDateTime now = LocalDateTime.of(2026, 7, 19, 12, 0);
        ShipmentRequest exact = ShipmentRequest.builder().createdAt(now.minusHours(48)).build();
        ShipmentRequest beyond = ShipmentRequest.builder().createdAt(now.minusHours(48).minusMinutes(1)).build();

        assertThat(ShipmentService.isStaleForDelivery(exact, 48, now)).isFalse();
        assertThat(ShipmentService.isStaleForDelivery(beyond, 48, now)).isTrue();
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "abc", "0", "-5"})
    void malformedOrNonPositiveThresholdFallsBackTo48(String configuredValue) {
        UUID companyId = UUID.randomUUID();
        ShipmentRequest request = responseShipment(companyId, LocalDateTime.now().minusHours(30));
        when(systemParameterService.getRawValue(
                ShipmentService.PARAM_STALE_WARNING_HOURS,
                null))
                .thenReturn(configuredValue);

        ShipmentRequestResponseDto response = service.toResponseDto(request);

        assertThat(response.getStaleThresholdHours()).isEqualTo(48);
        assertThat(response.getStaleForDelivery()).isFalse();
        assertThat(staleThresholdWarnEvents()).hasSize(1);
    }

    @Test
    void nullConfiguredThresholdFallsBackTo48() {
        UUID companyId = UUID.randomUUID();
        ShipmentRequest request = responseShipment(companyId, LocalDateTime.now().minusHours(49));
        when(systemParameterService.getRawValue(
                ShipmentService.PARAM_STALE_WARNING_HOURS,
                null))
                .thenReturn(null);

        ShipmentRequestResponseDto response = service.toResponseDto(request);

        assertThat(response.getStaleThresholdHours()).isEqualTo(48);
        assertThat(response.getStaleForDelivery()).isTrue();
        assertThat(staleThresholdWarnEvents()).isEmpty();
    }

    @Test
    void tenantEffectiveThresholdIsReflectedInResponseMetadata() {
        UUID companyId = UUID.randomUUID();
        ShipmentRequest request = responseShipment(companyId, LocalDateTime.now().minusHours(30));
        when(systemParameterService.getRawValue(
                ShipmentService.PARAM_STALE_WARNING_HOURS,
                null))
                .thenReturn("24");

        ShipmentRequestResponseDto response = service.toResponseDto(request);

        assertThat(response.getStaleThresholdHours()).isEqualTo(24);
        assertThat(response.getStaleForDelivery()).isTrue();
    }

    @Test
    void missingCreatedAtIsNonStaleAndDoesNotBlockConfirmedDeliver() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, null, ShipmentRequestStatus.SUBMITTED);
        stubDeliver(request, companyId);

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            assertThat(service.deliver(shipmentId, true).getStatus()).isEqualTo(ShipmentRequestStatus.DELIVERED);
        }

        verify(auditLogService, never()).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void stockBookingFailureWritesNoConfirmationAuditAndLeavesStatusUntouched() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, LocalDateTime.now().minusHours(49), ShipmentRequestStatus.SUBMITTED);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId)).thenReturn(Optional.of(request));
        doThrow(new ValidationException("nincs fedezet"))
                .when(stockBookingService).bookStockIn(request, companyId);

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            assertThatThrownBy(() -> service.deliver(shipmentId, true))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("fedezet");
        }

        assertThat(request.getStatus()).isEqualTo(ShipmentRequestStatus.SUBMITTED);
        verify(auditLogService, never()).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
        verify(repository, never()).save(any());
    }

    @Test
    void alreadyDeliveredConfirmedRequestConflictsWithoutConfirmationAudit() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId, companyId, LocalDateTime.now().minusHours(49), ShipmentRequestStatus.DELIVERED);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId)).thenReturn(Optional.of(request));

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            assertThatThrownBy(() -> service.deliver(shipmentId, true)).isInstanceOf(ConflictException.class);
        }

        verify(auditLogService, never()).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @ParameterizedTest
    @ValueSource(strings = {"DRAFT", "CANCELLED", "REJECTED"})
    void invalidStatusConfirmedRequestFailsWithoutConfirmationAudit(String statusName) {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        ShipmentRequest request = deliverableShipment(
                shipmentId,
                companyId,
                LocalDateTime.now().minusHours(49),
                ShipmentRequestStatus.valueOf(statusName));
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId)).thenReturn(Optional.of(request));

        try (MockedStatic<SecurityUtils> security = securityContext(companyId, 77L, request.getToBranchId())) {
            assertThatThrownBy(() -> service.deliver(shipmentId, true)).isInstanceOf(ValidationException.class);
        }

        verify(auditLogService, never()).log(
                eq(ShipmentService.ACTION_DELIVER_CONFIRMED_STALE),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    private void stubDeliver(ShipmentRequest request, UUID companyId) {
        when(repository.findByIdAndCompanyIdForUpdate(request.getId(), companyId))
                .thenReturn(Optional.of(request));
        when(repository.save(request)).thenReturn(request);
    }

    private ShipmentRequest responseShipment(UUID companyId, LocalDateTime createdAt) {
        UUID fromBranchId = UUID.randomUUID();
        UUID toBranchId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        when(branchRepository.findByIdAndCompanyId(fromBranchId, companyId))
                .thenReturn(Optional.of(Branch.builder().id(fromBranchId).company(company).build()));
        when(branchRepository.findByIdAndCompanyId(toBranchId, companyId))
                .thenReturn(Optional.of(Branch.builder().id(toBranchId).company(company).build()));
        return ShipmentRequest.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .requestNumber("FF-000123")
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .status(ShipmentRequestStatus.SUBMITTED)
                .createdAt(createdAt)
                .items(new ArrayList<>())
                .build();
    }

    private ShipmentRequest deliverableShipment(
            UUID shipmentId,
            UUID companyId,
            LocalDateTime createdAt,
            ShipmentRequestStatus status) {
        UUID fromBranchId = UUID.randomUUID();
        UUID toBranchId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        when(branchRepository.findById(fromBranchId))
                .thenReturn(Optional.of(Branch.builder().id(fromBranchId).company(company).build()));
        when(branchRepository.findById(toBranchId))
                .thenReturn(Optional.of(Branch.builder().id(toBranchId).company(company).build()));
        return ShipmentRequest.builder()
                .id(shipmentId)
                .companyId(companyId)
                .requestNumber("FF-000123")
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .status(status)
                .createdAt(createdAt)
                .items(new ArrayList<>())
                .build();
    }

    private MockedStatic<SecurityUtils> securityContext(UUID companyId, Long workerId, UUID branchId) {
        MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
        security.when(SecurityUtils::getCurrentWorkerId).thenReturn(workerId);
        security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(branchId);
        return security;
    }

    private java.util.List<ILoggingEvent> staleThresholdWarnEvents() {
        return logAppender.list.stream()
                .filter(event -> Level.WARN.equals(event.getLevel()))
                .filter(event -> event.getFormattedMessage().contains("Érvénytelen Shipment stale küszöb"))
                .toList();
    }
}

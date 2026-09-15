package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-116: VAULT_COUNTERPARTY shipment submit/cancel — no partner cash_balance, auto-DELIVERED
 * outbound, human deliver inbound.
 */
@ExtendWith(MockitoExtension.class)
class ShipmentVaultCounterpartyFk116Test {

    @Mock private ShipmentRequestRepository repository;
    @Mock private hu.puzzleir.valuta.repository.BranchRepository branchRepository;
    @Mock private hu.puzzleir.valuta.repository.CurrencyRepository currencyRepository;
    @Mock private hu.puzzleir.valuta.repository.WorkerRepository workerRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private ShipmentStockBookingService stockBookingService;
    @Mock private ShipmentHandlingFeeSyncService handlingFeeSyncService;
    @Mock private ShipmentVatSupplySyncService vatSupplySyncService;
    @Mock private AccessScopeService accessScopeService;
    @Mock private AuditLogService auditLogService;
    @Mock private SystemParameterService systemParameterService;
    @Mock private HufDaybookSequenceService hufDaybookSequenceService;
    @Mock private hu.puzzleir.valuta.repository.CashBalanceRepository cashBalanceRepository;
    @Mock private hu.puzzleir.valuta.repository.CurrencyStockRepository currencyStockRepository;

    @InjectMocks
    private ShipmentService service;

    @BeforeEach
    void setUpAccessScope() {
        lenient().when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @Test
    @DisplayName("FR-1: vault → counterparty submit books sender OUT and auto-DELIVERED, no partner IN")
    void outgoingSubmitAutoDelivers() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        Fixture fx = fixture(companyId, shipmentId, vault(), counterparty(), ShipmentRequestStatus.DRAFT);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId))
                .thenReturn(java.util.Optional.of(fx.request));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            ShipmentRequest result = service.submit(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.DELIVERED);
        }
        verify(stockBookingService).bookStockOut(eq(fx.request), eq(companyId));
        verify(stockBookingService, never()).bookStockIn(any(), any());
        verify(auditLogService).log(
                eq(ShipmentService.ACTION_AUTO_DELIVERED),
                eq("ShipmentRequest"), eq(shipmentId.toString()), eq("77"),
                isNull(), isNull(), isNull(),
                org.mockito.ArgumentMatchers.argThat((String changes) ->
                        changes.contains("\"from_status\":\"DRAFT\"")
                                && changes.contains("\"to_status\":\"DELIVERED\"")),
                isNull(), isNull());
    }

    @Test
    @DisplayName("FR-2: counterparty → vault submit skips partner OUT and stays SUBMITTED")
    void incomingSubmitSkipsPartnerOut() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        Fixture fx = fixture(companyId, shipmentId, counterparty(), vault(), ShipmentRequestStatus.DRAFT);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId))
                .thenReturn(java.util.Optional.of(fx.request));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            ShipmentRequest result = service.submit(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.SUBMITTED);
        }
        verify(stockBookingService, never()).bookStockOut(any(), any());
        verify(stockBookingService, never()).bookStockIn(any(), any());
        verify(auditLogService).log(
                eq(ShipmentService.ACTION_SUBMITTED),
                eq("ShipmentRequest"), eq(shipmentId.toString()), eq("77"),
                isNull(), isNull(), isNull(),
                org.mockito.ArgumentMatchers.argThat((String changes) ->
                        changes.contains("\"to_status\":\"SUBMITTED\"")),
                isNull(), isNull());
    }

    @Test
    @DisplayName("FR-3a: auto-DELIVERED outbound cancel reverses vault OUT, not partner IN")
    void cancelAutoDeliveredOutgoingReversesSenderOnly() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        Fixture fx = fixture(companyId, shipmentId, vault(), counterparty(), ShipmentRequestStatus.DELIVERED);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId))
                .thenReturn(java.util.Optional.of(fx.request));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            ShipmentRequest result = service.cancel(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.CANCELLED);
        }
        verify(stockBookingService).assertSender(fx.request);
        verify(stockBookingService).reverseStockOut(eq(fx.request), eq(companyId));
        verify(stockBookingService, never()).reverseStockIn(any(), any());
    }

    @Test
    @DisplayName("FR-3b: incoming SUBMITTED cancel uses vault token and does not reverse partner OUT")
    void cancelIncomingSubmittedUsesVaultGuard() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        Fixture fx = fixture(companyId, shipmentId, counterparty(), vault(), ShipmentRequestStatus.SUBMITTED);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId))
                .thenReturn(java.util.Optional.of(fx.request));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            ShipmentRequest result = service.cancel(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.CANCELLED);
        }
        verify(stockBookingService).assertReceiver(fx.request);
        verify(stockBookingService, never()).assertSender(fx.request);
        verify(stockBookingService, never()).reverseStockOut(any(), any());
        verify(stockBookingService, never()).reverseStockIn(any(), any());
    }

    @Test
    @DisplayName("FR-3: incoming DELIVERED cancel reverses vault IN")
    void cancelIncomingDeliveredReversesVaultIn() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        Fixture fx = fixture(companyId, shipmentId, counterparty(), vault(), ShipmentRequestStatus.DELIVERED);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId))
                .thenReturn(java.util.Optional.of(fx.request));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(77L);
            ShipmentRequest result = service.cancel(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.CANCELLED);
        }
        verify(stockBookingService).assertReceiver(fx.request);
        verify(stockBookingService).reverseStockIn(eq(fx.request), eq(companyId));
        verify(stockBookingService, never()).reverseStockOut(any(), any());
    }

    private record Fixture(ShipmentRequest request, Branch from, Branch to) {
    }

    private Fixture fixture(UUID companyId, UUID shipmentId, Branch fromTemplate, Branch toTemplate,
                             ShipmentRequestStatus status) {
        UUID fromId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch from = Branch.builder()
                .id(fromId)
                .company(company)
                .isVault(fromTemplate.getIsVault())
                .branchType(fromTemplate.getBranchType())
                .build();
        Branch to = Branch.builder()
                .id(toId)
                .company(company)
                .isVault(toTemplate.getIsVault())
                .branchType(toTemplate.getBranchType())
                .build();
        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(java.util.Optional.of(from));
        when(branchRepository.findByIdAndCompanyId(toId, companyId)).thenReturn(java.util.Optional.of(to));
        when(branchRepository.findById(fromId)).thenReturn(java.util.Optional.of(from));
        when(branchRepository.findById(toId)).thenReturn(java.util.Optional.of(to));
        ShipmentRequest request = ShipmentRequest.builder()
                .id(shipmentId)
                .requestNumber("TRB-1")
                .fromBranchId(fromId)
                .toBranchId(toId)
                .status(status)
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(4L)
                        .requestedAmount(new BigDecimal("100"))
                        .build())))
                .build();
        return new Fixture(request, from, to);
    }

    private static Branch vault() {
        return Branch.builder()
                .isVault(true)
                .branchType(Dictionary.builder().category("BRANCH_TYPE").code("ERTEKTAR").name("Értéktár").build())
                .build();
    }

    private static Branch counterparty() {
        return Branch.builder()
                .isVault(false)
                .branchType(Dictionary.builder().category("BRANCH_TYPE").code("VAULT_COUNTERPARTY").name("TRB").build())
                .build();
    }
}

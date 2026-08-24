package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentServiceTerritoryScopeTest {

    private static final UUID COMPANY = UUID.randomUUID();
    private static final UUID OWN_VAULT = UUID.randomUUID();
    private static final UUID OWN_P2 = UUID.randomUUID();
    private static final UUID FOREIGN_B1 = UUID.randomUUID();
    private static final UUID FOREIGN_B2 = UUID.randomUUID();
    private static final UUID SHIPMENT_ID = UUID.randomUUID();

    private final Set<UUID> scope = Set.of(OWN_VAULT, OWN_P2);

    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private ShipmentStockBookingService stockBookingService;
    @Mock private ShipmentHandlingFeeSyncService handlingFeeSyncService;
    @Mock private ShipmentVatSupplySyncService vatSupplySyncService;
    @Mock private AccessScopeService accessScopeService;
    @Mock private SystemParameterService systemParameterService;

    @InjectMocks private ShipmentService service;

    @Test
    void findByIdResponse_foreignRegion_throws404() {
        ShipmentRequest request = shipment(FOREIGN_B1, FOREIGN_B2);
        stubTenantBranches(request);
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThatThrownBy(() -> service.findByIdResponse(SHIPMENT_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Szállítmánykérés nem található: " + SHIPMENT_ID);
        }
    }

    @Test
    void findByIdResponse_fromInScope_visible() {
        ShipmentRequest request = shipment(OWN_P2, FOREIGN_B1);
        stubTenantBranches(request);
        stubResponseBranches(request);
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThat(service.findByIdResponse(SHIPMENT_ID).getId()).isEqualTo(SHIPMENT_ID);
        }
    }

    @Test
    void findByIdResponse_toInScope_visible() {
        ShipmentRequest request = shipment(FOREIGN_B1, OWN_P2);
        stubTenantBranches(request);
        stubResponseBranches(request);
        stubScopedUser();

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThat(service.findByIdResponse(SHIPMENT_ID).getId()).isEqualTo(SHIPMENT_ID);
        }
    }

    @Test
    void findByIdResponse_nullScope_centralSeesAll() {
        ShipmentRequest request = shipment(FOREIGN_B1, FOREIGN_B2);
        stubTenantBranches(request);
        stubResponseBranches(request);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThat(service.findByIdResponse(SHIPMENT_ID).getId()).isEqualTo(SHIPMENT_ID);
        }
    }

    @Test
    void findAll_scopedUser_usesScopedQuery() {
        Pageable pageable = PageRequest.of(0, 20);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(scope);
        when(shipmentRequestRepository.findScopedByCompanyId(
                scope, OWN_P2, ShipmentRequestStatus.SUBMITTED, COMPANY, pageable))
                .thenReturn(Page.empty(pageable));

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThat(service.findAll(ShipmentRequestStatus.SUBMITTED, OWN_P2, pageable)).isEmpty();
        }

        verify(shipmentRequestRepository).findScopedByCompanyId(
                scope, OWN_P2, ShipmentRequestStatus.SUBMITTED, COMPANY, pageable);
        verify(shipmentRequestRepository, never()).findByBranchAndCompanyId(any(), any(), any(), any());
        verify(shipmentRequestRepository, never()).findByStatusAndCompanyId(any(), any(), any());
        verify(shipmentRequestRepository, never()).findAllOrderedByCompanyId(any(), any());
    }

    @Test
    void findAll_emptyScope_failClosedEmptyPage() {
        Pageable pageable = PageRequest.of(0, 20);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(Set.of());

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            Page<ShipmentRequest> result = service.findAll(null, null, pageable);
            assertThat(result.getContent()).isEmpty();
            assertThat(result.getTotalElements()).isZero();
        }

        verifyNoInteractions(shipmentRequestRepository);
    }

    @Test
    void findAll_nullScope_legacyBranchesUnchanged() {
        Pageable pageable = PageRequest.of(0, 20);
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
        when(shipmentRequestRepository.findByBranchAndCompanyId(
                OWN_P2, ShipmentRequestStatus.SUBMITTED, COMPANY, pageable)).thenReturn(Page.empty(pageable));
        when(shipmentRequestRepository.findByStatusAndCompanyId(
                ShipmentRequestStatus.APPROVED, COMPANY, pageable)).thenReturn(Page.empty(pageable));
        when(shipmentRequestRepository.findAllOrderedByCompanyId(COMPANY, pageable)).thenReturn(Page.empty(pageable));

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThat(service.findAll(ShipmentRequestStatus.SUBMITTED, OWN_P2, pageable)).isEmpty();
            assertThat(service.findAll(ShipmentRequestStatus.APPROVED, null, pageable)).isEmpty();
            assertThat(service.findAll(null, null, pageable)).isEmpty();
        }

        verify(shipmentRequestRepository).findByBranchAndCompanyId(
                OWN_P2, ShipmentRequestStatus.SUBMITTED, COMPANY, pageable);
        verify(shipmentRequestRepository).findByStatusAndCompanyId(
                ShipmentRequestStatus.APPROVED, COMPANY, pageable);
        verify(shipmentRequestRepository).findAllOrderedByCompanyId(COMPANY, pageable);
        verify(shipmentRequestRepository, never()).findScopedByCompanyId(any(), any(), any(), any(), any());
    }

    @Test
    void writePathUnaffected_findByIdDoesNotTerritoryGuard() {
        ShipmentRequest request = shipment(FOREIGN_B1, FOREIGN_B2);
        stubTenantBranches(request);

        try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
            assertThat(service.findById(SHIPMENT_ID)).isSameAs(request);
        }

        verifyNoInteractions(accessScopeService);
    }

    private void stubScopedUser() {
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(scope);
        when(accessScopeService.isBranchVisible(any(), anyString()))
                .thenAnswer(invocation -> {
                    Set<UUID> candidateScope = invocation.getArgument(0);
                    String id = invocation.getArgument(1);
                    return candidateScope == null || (id != null && candidateScope.contains(UUID.fromString(id)));
                });
    }

    private ShipmentRequest shipment(UUID fromBranchId, UUID toBranchId) {
        ShipmentRequest request = ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY)
                .requestNumber("AT-000042")
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .status(ShipmentRequestStatus.SUBMITTED)
                .items(new ArrayList<>())
                .build();
        when(shipmentRequestRepository.findByIdAndCompanyId(SHIPMENT_ID, COMPANY))
                .thenReturn(Optional.of(request));
        return request;
    }

    private void stubTenantBranches(ShipmentRequest request) {
        Company company = Company.builder().id(COMPANY).build();
        when(branchRepository.findById(request.getFromBranchId()))
                .thenReturn(Optional.of(branch(request.getFromBranchId(), "BR001", company)));
        when(branchRepository.findById(request.getToBranchId()))
                .thenReturn(Optional.of(branch(request.getToBranchId(), "BR002", company)));
    }

    private void stubResponseBranches(ShipmentRequest request) {
        Company company = Company.builder().id(COMPANY).build();
        when(branchRepository.findByIdAndCompanyId(request.getFromBranchId(), COMPANY))
                .thenReturn(Optional.of(branch(request.getFromBranchId(), "BR001", company)));
        when(branchRepository.findByIdAndCompanyId(request.getToBranchId(), COMPANY))
                .thenReturn(Optional.of(branch(request.getToBranchId(), "BR002", company)));
    }

    private Branch branch(UUID id, String code, Company company) {
        return Branch.builder().id(id).code(code).name(code).company(company).build();
    }

    private MockedStatic<SecurityUtils> security(UUID companyId) {
        MockedStatic<SecurityUtils> security = org.mockito.Mockito.mockStatic(SecurityUtils.class);
        security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
        return security;
    }

    @Nested
    @ExtendWith(MockitoExtension.class)
    class HandlingFeeReadGuard {

        @Mock private ShipmentService shipmentService;
        @Mock private HandlingFeeService handlingFeeService;
        @Mock private ShipmentHandlingFeeRepository feeRepository;
        @Mock private CurrencyRepository feeCurrencyRepository;
        @Mock private AuditLogService auditLogService;

        @InjectMocks private ShipmentHandlingFeeService feeService;

        @Test
        void findByShipmentId_foreignRegionShipment_throws404() {
            doThrow(new ResourceNotFoundException("Szállítmánykérés nem található: " + SHIPMENT_ID))
                    .when(shipmentService).assertShipmentTerritoryVisible(SHIPMENT_ID);

            assertThatThrownBy(() -> feeService.findByShipmentId(SHIPMENT_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Szállítmánykérés nem található: " + SHIPMENT_ID);

            verifyNoInteractions(feeRepository);
        }

        @Test
        void findByShipmentId_inScope_returnsFee() {
            ShipmentHandlingFee fee = ShipmentHandlingFee.builder()
                    .id(UUID.randomUUID())
                    .companyId(COMPANY)
                    .shipmentRequestId(SHIPMENT_ID)
                    .sourceBranchId(OWN_P2)
                    .hufAmount(new BigDecimal("100000"))
                    .calculatedFee(new BigDecimal("500"))
                    .status(ShipmentRequestStatus.SUBMITTED)
                    .build();
            when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY))
                    .thenReturn(Optional.of(fee));

            try (MockedStatic<SecurityUtils> security = security(COMPANY)) {
                assertThat(feeService.findByShipmentId(SHIPMENT_ID)).isNotNull();
            }

            verify(shipmentService).assertShipmentTerritoryVisible(SHIPMENT_ID);
        }
    }
}

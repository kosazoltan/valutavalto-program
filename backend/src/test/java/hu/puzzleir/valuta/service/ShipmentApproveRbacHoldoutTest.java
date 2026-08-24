package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.MockitoAnnotations;
import org.springframework.security.access.AccessDeniedException;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-018 holdout: a deprecated approve minden Shipmentnél ugyanazt a sender-only guardot
 * használja. Sem a {@code KK} prefix, sem a kezelési díj sor léte nem nyithat külön receiver/
 * négy-szem jóváhagyási ágat; a cél- vagy null branch tiltott, a küldő branch kompatibilisen él.
 */
class ShipmentApproveRbacHoldoutTest {

    @Mock private ShipmentRequestRepository repository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private TransferSerialSequenceService transferSerialSequenceService;
    @Mock private AuditLogService auditLogService;
    @Mock private ShipmentHandlingFeeSyncService handlingFeeSyncService;
    @Mock private ShipmentVatSupplySyncService vatSupplySyncService;
    @Mock private AccessScopeService accessScopeService;
    @Mock private SystemParameterService systemParameterService;
    @Mock private HufDaybookSequenceService hufDaybookSequenceService;

    private AutoCloseable mocks;

    @BeforeEach
    void setUp() {
        mocks = MockitoAnnotations.openMocks(this);
    }

    private ShipmentService serviceWithRealStockBookingService() {
        ShipmentStockBookingService realStockBookingService = new ShipmentStockBookingService(
                branchRepository,
                cashBalanceRepository,
                currencyStockRepository,
                currencyRepository,
                auditLogService);
        return new ShipmentService(
                repository,
                branchRepository,
                currencyRepository,
                workerRepository,
                exchangeRateService,
                transferSerialSequenceService,
                realStockBookingService,
                handlingFeeSyncService,
                vatSupplySyncService,
                accessScopeService,
                auditLogService,
                systemParameterService,
                hufDaybookSequenceService);
    }

    private ShipmentRequest submittedShipment(UUID shipmentId, UUID companyId, String serialPrefix) {
        UUID fromBranch = UUID.randomUUID();
        UUID toBranch = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch from = Branch.builder().id(fromBranch).company(company).build();
        Branch to = Branch.builder().id(toBranch).company(company).build();
        when(branchRepository.findById(fromBranch)).thenReturn(Optional.of(from));
        when(branchRepository.findById(toBranch)).thenReturn(Optional.of(to));
        return ShipmentRequest.builder()
                .id(shipmentId)
                .requestNumber((serialPrefix != null ? serialPrefix : "AT") + "-000999")
                .serialPrefix(serialPrefix)
                .fromBranchId(fromBranch)
                .toBranchId(toBranch)
                .status(ShipmentRequestStatus.SUBMITTED)
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(4L)
                        .requestedAmount(new BigDecimal("300"))
                        .build())))
                .build();
    }

    @Test
    void kkPrefixWithoutFeeRow_takesFromOnlyPath_VVAUTH002_notFeePath() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        // "KK" prefix önmagában sem nyithat receiver approve ágat.
        ShipmentRequest sr = submittedShipment(shipmentId, companyId, "KK");
        sr.setRequestedById(77L);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId)).thenReturn(Optional.of(sr));
        ShipmentService svc = serviceWithRealStockBookingService();


        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            // A CÉL (to) branch NEM-rögzítő workere: a fee-ágon ENGEDETT lenne, a from-only ágon TILT.
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(sr.getToBranchId());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(88L); // != rögzítő

            assertThatThrownBy(() -> svc.approve(shipmentId))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("VV-AUTH-002");   // from-only út — NEM VV-AUTH-003/004
        }
        assertThat(sr.getStatus()).isEqualTo(ShipmentRequestStatus.SUBMITTED);
        verify(repository, never()).save(any());
        verify(handlingFeeSyncService, never()).syncFromShipment(any());
        verify(handlingFeeSyncService, never()).isHandlingFeeShipment(any());
    }

    @Test
    void feeRowWithoutKkPrefix_usesSameDeprecatedSenderGuardAsEveryShipment() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        // NINCS "KK" prefix (sőt null), DE VAN fee-sor: FKH-018 után ez sem nyithat
        // külön négy-szem/receiver approve ágat; a deprecated út sender-only marad.
        ShipmentRequest sr = submittedShipment(shipmentId, companyId, null);
        sr.setRequestedById(77L);
        when(repository.findByIdAndCompanyIdForUpdate(shipmentId, companyId)).thenReturn(Optional.of(sr));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        ShipmentService svc = serviceWithRealStockBookingService();

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(sr.getFromBranchId());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(88L); // != rögzítő

            ShipmentRequest result = svc.approve(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.APPROVED);
        }
        verify(handlingFeeSyncService).syncFromShipment(sr);
        verify(handlingFeeSyncService, never()).isHandlingFeeShipment(any());
    }
}

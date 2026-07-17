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
 * HOLDOUT H1 (a coder NEM látta) — a fee-jel a shipment_handling_fee SOR, NEM a "KK" címke.
 *
 * <p>Anti-spoof: egy "ügyes" implementáció a {@code serialPrefix == "KK"} rövidítéssel is zöldre
 * vihetné a publikus terv tesztjeit (azok mindig konzisztens fixture-t adnak). Ez a próba
 * szétválasztja a két jelet: a KK-prefix ÖNMAGÁBAN nem nyithatja ki a fee-ágat, és a fee-ág
 * KIZÁRÓLAG a fee-sor létén (isHandlingFeeShipment) múlik.
 *
 * <p>Ha ez bukik: a coder string-konvencióra épített auth-döntést (terv B-alternatíva, ELVETVE) →
 * gyökérok-hiba, a kódot kell javítani, nem a próbát.
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
                org.mockito.Mockito.mock(AccessScopeService.class));
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
        // "KK" prefix, DE nincs fee-sor: isHandlingFeeShipment == false → from-only ág kell.
        ShipmentRequest sr = submittedShipment(shipmentId, companyId, "KK");
        sr.setRequestedById(77L);
        when(repository.findById(shipmentId)).thenReturn(Optional.of(sr));
        ShipmentService svc = serviceWithRealStockBookingService();
        when(handlingFeeSyncService.isHandlingFeeShipment(sr)).thenReturn(false);

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
    }

    @Test
    void feeRowWithoutKkPrefix_takesFeePath_approvedForToBranchNonRequester() {
        UUID companyId = UUID.randomUUID();
        UUID shipmentId = UUID.randomUUID();
        // NINCS "KK" prefix (sőt null), DE VAN fee-sor: a döntés kizárólag a fee-jelen múlik.
        ShipmentRequest sr = submittedShipment(shipmentId, companyId, null);
        sr.setRequestedById(77L);
        when(repository.findById(shipmentId)).thenReturn(Optional.of(sr));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        ShipmentService svc = serviceWithRealStockBookingService();
        when(handlingFeeSyncService.isHandlingFeeShipment(sr)).thenReturn(true);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            security.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(sr.getToBranchId());
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(88L); // != rögzítő

            ShipmentRequest result = svc.approve(shipmentId);
            assertThat(result.getStatus()).isEqualTo(ShipmentRequestStatus.APPROVED);
        }
        verify(handlingFeeSyncService).syncFromShipment(sr);
    }
}

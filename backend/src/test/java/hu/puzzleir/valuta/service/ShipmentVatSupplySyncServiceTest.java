package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.ShipmentVatSupplyItem;
import hu.puzzleir.valuta.entity.VatSupplyStock;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentVatSupplyItemRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentVatSupplySyncServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID SHIPMENT_ID = UUID.randomUUID();
    private static final UUID FROM_ID = UUID.randomUUID();
    private static final UUID TO_ID = UUID.randomUUID();

    @Mock private ShipmentVatSupplyItemRepository itemRepository;
    @Mock private VatSupplyStockRepository stockRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AuditLogService auditLogService;

    @InjectMocks private ShipmentVatSupplySyncService service;

    @Test
    void deliver_creditsVaultTerritoryStockIdempotently() {
        ShipmentVatSupplyItem item = ShipmentVatSupplyItem.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .shipmentRequestId(SHIPMENT_ID)
                .fromBranchId(FROM_ID)
                .toBranchId(TO_ID)
                .hufAmount(new BigDecimal("10000"))
                .status(ShipmentRequestStatus.SUBMITTED)
                .stockApplied(false)
                .build();
        ShipmentRequest shipment = ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY_ID)
                .status(ShipmentRequestStatus.DELIVERED)
                .build();
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(item));
        when(branchRepository.findByIdAndCompanyId(FROM_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(FROM_ID).isVault(false).build()));
        when(branchRepository.findByIdAndCompanyId(TO_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(TO_ID).isVault(true).vaultTerritoryId(9).build()));
        when(stockRepository.findByCompanyIdAndVaultTerritoryId(COMPANY_ID, 9))
                .thenReturn(Optional.empty());
        when(stockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(itemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W");
            service.syncFromShipment(shipment);
            service.syncFromShipment(shipment); // idempotent — stockApplied
        }

        ArgumentCaptor<VatSupplyStock> stockCaptor = ArgumentCaptor.forClass(VatSupplyStock.class);
        verify(stockRepository, times(1)).save(stockCaptor.capture());
        assertThat(stockCaptor.getValue().getCurrentBalance()).isEqualByComparingTo("10000");
        assertThat(item.isStockApplied()).isTrue();
    }

    @Test
    void deliver_debitsWhenFromIsVault() {
        ShipmentVatSupplyItem item = ShipmentVatSupplyItem.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .shipmentRequestId(SHIPMENT_ID)
                .fromBranchId(FROM_ID)
                .toBranchId(TO_ID)
                .hufAmount(new BigDecimal("3000"))
                .status(ShipmentRequestStatus.SUBMITTED)
                .stockApplied(false)
                .build();
        ShipmentRequest shipment = ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY_ID)
                .status(ShipmentRequestStatus.APPROVED)
                .build();
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(item));
        when(branchRepository.findByIdAndCompanyId(FROM_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(FROM_ID).isVault(true).vaultTerritoryId(3).build()));
        when(branchRepository.findByIdAndCompanyId(TO_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(TO_ID).isVault(false).build()));
        when(stockRepository.findByCompanyIdAndVaultTerritoryId(COMPANY_ID, 3))
                .thenReturn(Optional.of(VatSupplyStock.builder()
                        .companyId(COMPANY_ID)
                        .vaultTerritoryId(3)
                        .currentBalance(new BigDecimal("10000"))
                        .build()));
        when(stockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(itemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W");
            service.syncFromShipment(shipment);
        }

        ArgumentCaptor<VatSupplyStock> stockCaptor = ArgumentCaptor.forClass(VatSupplyStock.class);
        verify(stockRepository).save(stockCaptor.capture());
        assertThat(stockCaptor.getValue().getCurrentBalance()).isEqualByComparingTo("7000");
    }

    @Test
    void debit_beyondBalance_isRejectedAndLeavesStockUntouched() {
        ShipmentVatSupplyItem item = item(new BigDecimal("12000"));
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(item));
        when(branchRepository.findByIdAndCompanyId(FROM_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(FROM_ID).isVault(true).vaultTerritoryId(3).build()));
        when(branchRepository.findByIdAndCompanyId(TO_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(TO_ID).isVault(false).build()));
        when(stockRepository.findByCompanyIdAndVaultTerritoryId(COMPANY_ID, 3))
                .thenReturn(Optional.of(VatSupplyStock.builder()
                        .companyId(COMPANY_ID)
                        .vaultTerritoryId(3)
                        .currentBalance(new BigDecimal("10000"))
                        .build()));

        assertThatThrownBy(() -> service.syncFromShipment(shipment(ShipmentRequestStatus.APPROVED)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("negatívba");

        verify(stockRepository, never()).save(any());
        verify(itemRepository, never()).save(any());
        assertThat(item.isStockApplied()).isFalse();
    }

    @Test
    void neitherSideIsVault_isRejected() {
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(item(new BigDecimal("5000"))));
        when(branchRepository.findByIdAndCompanyId(FROM_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(FROM_ID).isVault(false).build()));
        when(branchRepository.findByIdAndCompanyId(TO_ID, COMPANY_ID))
                .thenReturn(Optional.of(Branch.builder().id(TO_ID).isVault(false).build()));

        assertThatThrownBy(() -> service.syncFromShipment(shipment(ShipmentRequestStatus.DELIVERED)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("értéktár");

        verify(stockRepository, never()).save(any());
    }

    @Test
    void submittedStatus_mirrorsStatusWithoutBookingStock() {
        ShipmentVatSupplyItem item = item(new BigDecimal("5000"));
        item.setStatus(ShipmentRequestStatus.DRAFT);
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(item));
        when(itemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.syncFromShipment(shipment(ShipmentRequestStatus.SUBMITTED));

        assertThat(item.getStatus()).isEqualTo(ShipmentRequestStatus.SUBMITTED);
        assertThat(item.isStockApplied()).isFalse();
        verify(stockRepository, never()).save(any());
        verifyNoInteractions(branchRepository, auditLogService);
    }

    @Test
    void assertNotVatSupplyShipment_rowExists_throwsValidation() {
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(item(new BigDecimal("5000"))));

        assertThatThrownBy(() -> service.assertNotVatSupplyShipment(shipment(ShipmentRequestStatus.DRAFT)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("generikus");
    }

    private static ShipmentVatSupplyItem item(BigDecimal hufAmount) {
        return ShipmentVatSupplyItem.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .shipmentRequestId(SHIPMENT_ID)
                .fromBranchId(FROM_ID)
                .toBranchId(TO_ID)
                .hufAmount(hufAmount)
                .status(ShipmentRequestStatus.SUBMITTED)
                .stockApplied(false)
                .build();
    }

    private static ShipmentRequest shipment(ShipmentRequestStatus status) {
        return ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY_ID)
                .status(status)
                .build();
    }
}

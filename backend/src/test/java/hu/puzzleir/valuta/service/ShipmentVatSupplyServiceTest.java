package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.ShipmentVatSupplyItem;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentVatSupplyItemRepository;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentVatSupplyServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID SHIPMENT_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID ITEM_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID FROM_BRANCH_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");
    private static final UUID TO_BRANCH_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");

    @Mock private ShipmentService shipmentService;
    @Mock private ShipmentVatSupplyItemRepository itemRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private AuditLogService auditLogService;

    @InjectMocks private ShipmentVatSupplyService service;

    @Test
    void create_roundsHufAndPersistsWithoutFee() {
        ShipmentRequest saved = ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY_ID)
                .fromBranchId(FROM_BRANCH_ID)
                .toBranchId(TO_BRANCH_ID)
                .requestNumber("AS-000001")
                .status(ShipmentRequestStatus.DRAFT)
                .build();
        when(currencyRepository.findByCode("HUF"))
                .thenReturn(Optional.of(Currency.builder().id(6L).code("HUF").build()));
        when(shipmentService.create(any(ShipmentRequest.class), eq("AS"))).thenReturn(saved);
        when(itemRepository.save(any(ShipmentVatSupplyItem.class))).thenAnswer(inv -> {
            ShipmentVatSupplyItem item = inv.getArgument(0);
            item.setId(ITEM_ID);
            return item;
        });
        when(shipmentService.toResponseDto(saved))
                .thenReturn(ShipmentRequestResponseDto.builder().id(SHIPMENT_ID).build());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            service.create(validRequest(new BigDecimal("125003")));
        }

        ArgumentCaptor<ShipmentVatSupplyItem> captor = ArgumentCaptor.forClass(ShipmentVatSupplyItem.class);
        verify(itemRepository).save(captor.capture());
        assertThat(captor.getValue().getHufAmount()).isEqualByComparingTo("125005");
        assertThat(captor.getValue().isStockApplied()).isFalse();
        verify(shipmentService).create(any(ShipmentRequest.class), eq("AS"));
    }

    @Test
    void create_rejectsNonPositiveAfterRounding() {
        // Az összeg-ellenőrzés a HUF-törzs lekérdezése ELŐTT fut (KK-mintával azonos),
        // ezért itt nincs currency-stub — a shipment és a napló-sor sem jön létre.
        assertThatThrownBy(() -> service.create(validRequest(new BigDecimal("0"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitív");

        verifyNoInteractions(shipmentService, itemRepository, currencyRepository);
    }

    @Test
    void findByShipmentId_notFound_throwsResourceNotFound() {
        when(itemRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.findByShipmentId(SHIPMENT_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining(SHIPMENT_ID.toString());
        }
        verify(shipmentService).assertShipmentTerritoryVisible(SHIPMENT_ID);
    }

    private static ShipmentVatSupplyCreateRequest validRequest(BigDecimal amount) {
        return ShipmentVatSupplyCreateRequest.builder()
                .fromBranchId(FROM_BRANCH_ID)
                .toBranchId(TO_BRANCH_ID)
                .hufAmount(amount)
                .carrierName("Saja")
                .sealNumber("PL-1")
                .build();
    }
}

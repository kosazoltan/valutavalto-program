package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentHandlingFeeServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID SHIPMENT_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID FEE_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID FROM_BRANCH_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");
    private static final UUID TO_BRANCH_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");

    @Mock private ShipmentService shipmentService;
    @Mock private HandlingFeeService handlingFeeService;
    @Mock private ShipmentHandlingFeeRepository feeRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private AuditLogService auditLogService;

    @InjectMocks private ShipmentHandlingFeeService service;

    @Test
    void create_happyPath() {
        ShipmentRequest savedShipment = savedShipment();
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufCurrency()));
        when(shipmentService.create(any(ShipmentRequest.class), eq("KK"))).thenReturn(savedShipment);
        when(handlingFeeService.calculateHandlingFee(new BigDecimal("125000"), FROM_BRANCH_ID))
                .thenReturn(new BigDecimal("625"));
        when(feeRepository.save(any(ShipmentHandlingFee.class))).thenAnswer(invocation -> {
            ShipmentHandlingFee fee = invocation.getArgument(0);
            fee.setId(FEE_ID);
            return fee;
        });
        when(shipmentService.toResponseDto(savedShipment))
                .thenReturn(ShipmentRequestResponseDto.builder().id(SHIPMENT_ID).build());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");

            service.create(validRequest(new BigDecimal("125000")));
        }

        ArgumentCaptor<ShipmentRequest> shipmentCaptor = ArgumentCaptor.forClass(ShipmentRequest.class);
        verify(shipmentService).create(shipmentCaptor.capture(), eq("KK"));
        ShipmentRequest createdShipment = shipmentCaptor.getValue();
        assertThat(createdShipment.getItems()).hasSize(1);
        assertThat(createdShipment.getItems().getFirst().getCurrencyId()).isEqualTo(6L);
        assertThat(createdShipment.getItems().getFirst().getRequestedAmount())
                .isEqualByComparingTo("125000");

        ArgumentCaptor<ShipmentHandlingFee> feeCaptor = ArgumentCaptor.forClass(ShipmentHandlingFee.class);
        verify(feeRepository).save(feeCaptor.capture());
        ShipmentHandlingFee fee = feeCaptor.getValue();
        assertThat(fee.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(fee.getShipmentRequestId()).isEqualTo(SHIPMENT_ID);
        assertThat(fee.getSourceBranchId()).isEqualTo(FROM_BRANCH_ID);
        assertThat(fee.getHufAmount()).isEqualByComparingTo("125000");
        assertThat(fee.getCalculatedFee()).isEqualByComparingTo("625");
        assertThat(fee.getStatus()).isEqualTo(ShipmentRequestStatus.DRAFT);
        verify(handlingFeeService).calculateHandlingFee(new BigDecimal("125000"), FROM_BRANCH_ID);
        verify(auditLogService).log(
                eq(ShipmentHandlingFeeService.ACTION_FEE_RECEIVED),
                eq("ShipmentHandlingFee"),
                eq(FEE_ID.toString()),
                eq("42"),
                eq("KOSA"),
                eq(FROM_BRANCH_ID.toString()),
                eq(null),
                any(String.class),
                eq(null),
                eq(null));
    }

    @Test
    void create_roundsHufAmountToFive() {
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufCurrency()));
        when(shipmentService.create(any(ShipmentRequest.class), eq("KK"))).thenReturn(savedShipment());
        when(handlingFeeService.calculateHandlingFee(new BigDecimal("125005"), FROM_BRANCH_ID))
                .thenReturn(new BigDecimal("625"));
        when(feeRepository.save(any(ShipmentHandlingFee.class))).thenAnswer(invocation -> {
            ShipmentHandlingFee fee = invocation.getArgument(0);
            fee.setId(FEE_ID);
            return fee;
        });

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            service.create(validRequest(new BigDecimal("125003")));
        }

        ArgumentCaptor<ShipmentRequest> shipmentCaptor = ArgumentCaptor.forClass(ShipmentRequest.class);
        verify(shipmentService).create(shipmentCaptor.capture(), eq("KK"));
        assertThat(shipmentCaptor.getValue().getItems().getFirst().getRequestedAmount())
                .isEqualByComparingTo("125005");
        ArgumentCaptor<ShipmentHandlingFee> feeCaptor = ArgumentCaptor.forClass(ShipmentHandlingFee.class);
        verify(feeRepository).save(feeCaptor.capture());
        assertThat(feeCaptor.getValue().getHufAmount()).isEqualByComparingTo("125005");
        verify(handlingFeeService).calculateHandlingFee(new BigDecimal("125005"), FROM_BRANCH_ID);
    }

    @Test
    void create_zeroAmount_throwsValidation() {
        assertThatThrownBy(() -> service.create(validRequest(BigDecimal.ZERO)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitív");

        verifyNoInteractions(shipmentService, feeRepository);
    }

    @Test
    void create_negativeAmount_throwsValidation() {
        assertThatThrownBy(() -> service.create(validRequest(new BigDecimal("-5000"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitív");

        verifyNoInteractions(shipmentService, feeRepository);
    }

    @Test
    void create_missingHufCurrency_throwsValidation() {
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.create(validRequest(new BigDecimal("125000"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("HUF");

        verifyNoInteractions(shipmentService, feeRepository);
    }

    @Test
    void create_crossTenantBranch_propagatesValidation() {
        when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(hufCurrency()));
        when(shipmentService.create(any(ShipmentRequest.class), eq("KK")))
                .thenThrow(new ValidationException("Forrás fiók nem található a jelenlegi cégben"));

        assertThatThrownBy(() -> service.create(validRequest(new BigDecimal("125000"))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jelenlegi cégben");

        verify(feeRepository, never()).save(any());
    }

    @Test
    void findByShipmentId_notFound_throwsResourceNotFound() {
        when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.findByShipmentId(SHIPMENT_ID))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining(SHIPMENT_ID.toString());
        }
    }

    private static ShipmentHandlingFeeCreateRequest validRequest(BigDecimal hufAmount) {
        return ShipmentHandlingFeeCreateRequest.builder()
                .fromBranchId(FROM_BRANCH_ID)
                .toBranchId(TO_BRANCH_ID)
                .hufAmount(hufAmount)
                .notes("teszt")
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("FKH-018")
                .build();
    }

    private static ShipmentRequest savedShipment() {
        return ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY_ID)
                .requestNumber("KK-000001")
                .fromBranchId(FROM_BRANCH_ID)
                .toBranchId(TO_BRANCH_ID)
                .status(ShipmentRequestStatus.DRAFT)
                .build();
    }

    private static Currency hufCurrency() {
        return Currency.builder().id(6L).code("HUF").name("Forint").build();
    }
}

package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ShipmentHandlingFeeSyncServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID SHIPMENT_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID FEE_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID FROM_BRANCH_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");

    @Mock private ShipmentHandlingFeeRepository feeRepository;
    @Mock private AuditLogService auditLogService;

    @InjectMocks private ShipmentHandlingFeeSyncService service;

    @Test
    void sync_noFeeRow_noop() {
        ShipmentRequest shipment = shipment(ShipmentRequestStatus.SUBMITTED);
        when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.empty());

        service.syncFromShipment(shipment);

        verify(feeRepository, never()).save(any());
        verifyNoInteractions(auditLogService);
    }

    @Test
    void sync_approved_setsApprovedAtAndAudits() {
        ShipmentRequest shipment = shipment(ShipmentRequestStatus.APPROVED);
        ShipmentHandlingFee fee = fee(ShipmentRequestStatus.DRAFT, null);
        when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(fee));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            security.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            service.syncFromShipment(shipment);
        }

        assertThat(fee.getStatus()).isEqualTo(ShipmentRequestStatus.APPROVED);
        assertThat(fee.getApprovedAt()).isNotNull();
        verify(feeRepository).save(fee);
        verify(auditLogService).log(
                eq(ShipmentHandlingFeeSyncService.ACTION_FEE_APPROVED),
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
    void sync_approvedTwice_auditsOnce() {
        LocalDateTime approvedAt = LocalDateTime.of(2026, 7, 14, 9, 0);
        ShipmentHandlingFee fee = fee(ShipmentRequestStatus.APPROVED, approvedAt);
        when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(fee));

        service.syncFromShipment(shipment(ShipmentRequestStatus.APPROVED));

        assertThat(fee.getApprovedAt()).isEqualTo(approvedAt);
        assertThat(fee.getStatus()).isEqualTo(ShipmentRequestStatus.APPROVED);
        verify(feeRepository).save(fee);
        verifyNoInteractions(auditLogService);
    }

    @Test
    void sync_cancelled_mirrorsStatus_noApprovalAudit() {
        ShipmentHandlingFee fee = fee(ShipmentRequestStatus.SUBMITTED, null);
        when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(fee));

        service.syncFromShipment(shipment(ShipmentRequestStatus.CANCELLED));

        assertThat(fee.getStatus()).isEqualTo(ShipmentRequestStatus.CANCELLED);
        assertThat(fee.getApprovedAt()).isNull();
        verify(feeRepository).save(fee);
        verifyNoInteractions(auditLogService);
    }

    @Test
    void assertNotHandlingFeeShipment_feeExists_throwsValidation() {
        ShipmentRequest shipment = shipment(ShipmentRequestStatus.DRAFT);
        when(feeRepository.findByShipmentRequestIdAndCompanyId(SHIPMENT_ID, COMPANY_ID))
                .thenReturn(Optional.of(fee(ShipmentRequestStatus.DRAFT, null)), Optional.empty());

        assertThatThrownBy(() -> service.assertNotHandlingFeeShipment(shipment))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("generikus");
        assertThatCode(() -> service.assertNotHandlingFeeShipment(shipment)).doesNotThrowAnyException();
    }

    private static ShipmentRequest shipment(ShipmentRequestStatus status) {
        return ShipmentRequest.builder()
                .id(SHIPMENT_ID)
                .companyId(COMPANY_ID)
                .status(status)
                .build();
    }

    private static ShipmentHandlingFee fee(ShipmentRequestStatus status, LocalDateTime approvedAt) {
        return ShipmentHandlingFee.builder()
                .id(FEE_ID)
                .companyId(COMPANY_ID)
                .shipmentRequestId(SHIPMENT_ID)
                .sourceBranchId(FROM_BRANCH_ID)
                .hufAmount(new BigDecimal("125000"))
                .calculatedFee(new BigDecimal("625"))
                .status(status)
                .approvedAt(approvedAt)
                .build();
    }
}

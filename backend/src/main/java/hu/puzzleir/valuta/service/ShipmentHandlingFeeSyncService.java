package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class ShipmentHandlingFeeSyncService {

    public static final String ACTION_FEE_APPROVED = "SHIPMENT_HANDLING_FEE_APPROVED";

    private final ShipmentHandlingFeeRepository feeRepository;
    private final AuditLogService auditLogService;

    @Transactional(propagation = Propagation.REQUIRED)
    public void syncFromShipment(ShipmentRequest shipment) {
        feeRepository.findByShipmentRequestIdAndCompanyId(shipment.getId(), shipment.getCompanyId())
                .ifPresent(fee -> syncExistingFee(shipment, fee));
    }

    private void syncExistingFee(ShipmentRequest shipment, ShipmentHandlingFee fee) {
        boolean newlyApproved = shipment.getStatus() == ShipmentRequestStatus.APPROVED
                && fee.getApprovedAt() == null;
        fee.setStatus(shipment.getStatus());
        if (newlyApproved) {
            fee.setApprovedAt(LocalDateTime.now());
            auditLogService.log(
                    ACTION_FEE_APPROVED,
                    "ShipmentHandlingFee",
                    fee.getId().toString(),
                    String.valueOf(SecurityUtils.getCurrentWorkerId()),
                    SecurityUtils.getCurrentWorkerCode(),
                    fee.getSourceBranchId().toString(),
                    null,
                    String.format(
                            "{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\",\"calculated_fee\":%s}",
                            shipment.getId(), fee.getCalculatedFee().toPlainString()),
                    null,
                    null);
            log.info("Shipment kezelési költség jóváhagyva: shipment={}", shipment.getId());
        }
        feeRepository.save(fee);
    }

    /**
     * KK fee-jel (2026-07-15): egy shipment akkor kezelési-díj (KK) típusú, ha tartozik hozzá
     * shipment_handling_fee sor (tenant-szűrt). Ugyanez a jel vezérli a syncFromShipment-et és
     * az approve() guard-elágazását (ShipmentService) — egyetlen igazságforrás.
     */
    @Transactional(readOnly = true)
    public boolean isHandlingFeeShipment(ShipmentRequest shipment) {
        return feeRepository.findByShipmentRequestIdAndCompanyId(
                shipment.getId(), shipment.getCompanyId()).isPresent();
    }

    @Transactional(readOnly = true)
    public void assertNotHandlingFeeShipment(ShipmentRequest shipment) {
        if (isHandlingFeeShipment(shipment)) {
            throw new ValidationException(
                    "Kezelési költség tétel a generikus szállítmány-módosítással nem szerkeszthető.");
        }
    }
}

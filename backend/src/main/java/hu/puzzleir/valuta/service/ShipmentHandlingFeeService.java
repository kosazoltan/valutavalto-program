package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateResponseDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ShipmentHandlingFeeService {

    public static final String ACTION_FEE_RECEIVED = "SHIPMENT_HANDLING_FEE_RECEIVED";
    public static final String SERIAL_PREFIX_HANDLING_FEE = "KK";

    private final ShipmentService shipmentService;
    private final HandlingFeeService handlingFeeService;
    private final ShipmentHandlingFeeRepository feeRepository;
    private final CurrencyRepository currencyRepository;
    private final AuditLogService auditLogService;

    public ShipmentHandlingFeeCreateResponseDto create(ShipmentHandlingFeeCreateRequest dto) {
        BigDecimal hufAmount = HungarianRounding.roundToFive(dto.getHufAmount());
        if (hufAmount.signum() <= 0) {
            throw new ValidationException("A kezelési költség összege pozitív kell legyen.");
        }

        Currency huf = currencyRepository.findByCode("HUF")
                .orElseThrow(() -> new ValidationException("HUF valutanem nem található a törzsben."));

        ShipmentRequest request = ShipmentRequest.builder()
                .fromBranchId(dto.getFromBranchId())
                .toBranchId(dto.getToBranchId())
                .deliveryDate(dto.getDeliveryDate())
                .notes(dto.getNotes())
                .carrierName(dto.getCarrierName())
                .sealNumber(dto.getSealNumber())
                .build();
        request.addItem(ShipmentRequestItem.builder()
                .currencyId(huf.getId())
                .requestedAmount(hufAmount)
                .build());

        ShipmentRequest saved = shipmentService.create(request, SERIAL_PREFIX_HANDLING_FEE);
        // FK-096/D3: a feladó iroda viseli a KK díjat — fail-closed, iroda-tudatos feloldás.
        BigDecimal calculatedFee = handlingFeeService.calculateHandlingFee(hufAmount, saved.getFromBranchId());

        ShipmentHandlingFee fee = feeRepository.save(ShipmentHandlingFee.builder()
                .companyId(saved.getCompanyId())
                .shipmentRequestId(saved.getId())
                .sourceBranchId(saved.getFromBranchId())
                .hufAmount(hufAmount)
                .calculatedFee(calculatedFee)
                .status(saved.getStatus())
                .build());

        auditLogService.log(
                ACTION_FEE_RECEIVED,
                "ShipmentHandlingFee",
                fee.getId().toString(),
                String.valueOf(SecurityUtils.getCurrentWorkerId()),
                SecurityUtils.getCurrentWorkerCode(),
                saved.getFromBranchId().toString(),
                null,
                String.format(
                        "{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\",\"request_number\":\"%s\","
                                + "\"source_branch_id\":\"%s\",\"huf_amount\":%s,\"calculated_fee\":%s}",
                        saved.getId(),
                        saved.getRequestNumber(),
                        saved.getFromBranchId(),
                        hufAmount.toPlainString(),
                        calculatedFee.toPlainString()),
                null,
                null);

        log.info("Shipment kezelési költség rögzítve: shipment={}, amount={}", saved.getId(), hufAmount);
        return ShipmentHandlingFeeCreateResponseDto.builder()
                .shipment(shipmentService.toResponseDto(saved))
                .handlingFee(ShipmentHandlingFeeDto.from(fee))
                .build();
    }

    @Transactional(readOnly = true)
    public ShipmentHandlingFeeDto findByShipmentId(UUID shipmentRequestId) {
        // Territory-scope guard (2026-07-15): idegen régió shipmentjének díja se olvasható (404).
        shipmentService.assertShipmentTerritoryVisible(shipmentRequestId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return feeRepository.findByShipmentRequestIdAndCompanyId(shipmentRequestId, companyId)
                .map(ShipmentHandlingFeeDto::from)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "A szállítmányhoz nem tartozik kezelési költség tétel: " + shipmentRequestId));
    }
}

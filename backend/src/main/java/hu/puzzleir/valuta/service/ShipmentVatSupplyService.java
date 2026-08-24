package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyCreateResponseDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentVatSupplyItem;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ShipmentVatSupplyItemRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * FKH-040: ÁFA átadás-átvétel napló rögzítése — shipment (AS prefix, 1 HUF tétel) és
 * {@link ShipmentVatSupplyItem} egy tranzakcióban.
 *
 * <p>A KK (kezelési költség) mintát követi, két szándékos eltéréssel:
 * (1) nincs díjszámítás — a rögzített HUF-összeg maga a tétel;
 * (2) az ÁFA-pénz NEM a currency_stock-ban él, hanem a {@code vat_supply_stock}
 * értéktár-területi egyenlegben (a mozgást a {@link ShipmentVatSupplySyncService} könyveli).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ShipmentVatSupplyService {

    public static final String ACTION_VAT_SUPPLY_RECEIVED = "SHIPMENT_VAT_SUPPLY_RECEIVED";
    public static final String SERIAL_PREFIX_VAT_SUPPLY = "AS";

    private final ShipmentService shipmentService;
    private final ShipmentVatSupplyItemRepository vatSupplyRepository;
    private final CurrencyRepository currencyRepository;
    private final AuditLogService auditLogService;

    public ShipmentVatSupplyCreateResponseDto create(ShipmentVatSupplyCreateRequest dto) {
        BigDecimal hufAmount = HungarianRounding.roundToFive(dto.getHufAmount());
        if (hufAmount.signum() <= 0) {
            throw new ValidationException("Az ÁFA-ellátmány összege pozitív kell legyen.");
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

        ShipmentRequest saved = shipmentService.create(request, SERIAL_PREFIX_VAT_SUPPLY);

        ShipmentVatSupplyItem item = vatSupplyRepository.save(ShipmentVatSupplyItem.builder()
                .companyId(saved.getCompanyId())
                .shipmentRequestId(saved.getId())
                .fromBranchId(saved.getFromBranchId())
                .toBranchId(saved.getToBranchId())
                .hufAmount(hufAmount)
                .status(saved.getStatus())
                .build());

        auditLogService.log(
                ACTION_VAT_SUPPLY_RECEIVED,
                "ShipmentVatSupplyItem",
                item.getId().toString(),
                String.valueOf(SecurityUtils.getCurrentWorkerId()),
                SecurityUtils.getCurrentWorkerCode(),
                saved.getFromBranchId().toString(),
                null,
                String.format(
                        "{\"KAT\":\"TX\",\"shipment_request_id\":\"%s\",\"request_number\":\"%s\","
                                + "\"from_branch_id\":\"%s\",\"to_branch_id\":\"%s\",\"huf_amount\":%s}",
                        saved.getId(),
                        saved.getRequestNumber(),
                        saved.getFromBranchId(),
                        saved.getToBranchId(),
                        hufAmount.toPlainString()),
                null,
                null);

        log.info("Shipment ÁFA-ellátmány rögzítve: shipment={}, amount={}", saved.getId(), hufAmount);
        return ShipmentVatSupplyCreateResponseDto.builder()
                .shipment(shipmentService.toResponseDto(saved))
                .vatSupply(ShipmentVatSupplyDto.from(item))
                .build();
    }

    @Transactional(readOnly = true)
    public ShipmentVatSupplyDto findByShipmentId(UUID shipmentRequestId) {
        // Territory-scope guard (KK-mintával azonos): idegen régió shipmentje se olvasható (404).
        shipmentService.assertShipmentTerritoryVisible(shipmentRequestId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vatSupplyRepository.findByShipmentRequestIdAndCompanyId(shipmentRequestId, companyId)
                .map(ShipmentVatSupplyDto::from)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "A szállítmányhoz nem tartozik ÁFA-ellátmány tétel: " + shipmentRequestId));
    }
}

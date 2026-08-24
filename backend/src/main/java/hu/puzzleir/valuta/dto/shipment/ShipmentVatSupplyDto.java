package hu.puzzleir.valuta.dto.shipment;

import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.entity.ShipmentVatSupplyItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentVatSupplyDto {

    private UUID id;
    private UUID shipmentRequestId;
    private UUID fromBranchId;
    private UUID toBranchId;
    private BigDecimal hufAmount;
    private ShipmentRequestStatus status;
    private boolean stockApplied;
    private LocalDateTime createdAt;
    private LocalDateTime approvedAt;

    public static ShipmentVatSupplyDto from(ShipmentVatSupplyItem item) {
        return ShipmentVatSupplyDto.builder()
                .id(item.getId())
                .shipmentRequestId(item.getShipmentRequestId())
                .fromBranchId(item.getFromBranchId())
                .toBranchId(item.getToBranchId())
                .hufAmount(item.getHufAmount())
                .status(item.getStatus())
                .stockApplied(item.isStockApplied())
                .createdAt(item.getCreatedAt())
                .approvedAt(item.getApprovedAt())
                .build();
    }
}

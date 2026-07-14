package hu.puzzleir.valuta.dto.shipment;

import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
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
public class ShipmentHandlingFeeDto {

    private UUID id;
    private UUID shipmentRequestId;
    private UUID sourceBranchId;
    private BigDecimal hufAmount;
    private BigDecimal calculatedFee;
    private ShipmentRequestStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime approvedAt;

    public static ShipmentHandlingFeeDto from(ShipmentHandlingFee fee) {
        return ShipmentHandlingFeeDto.builder()
                .id(fee.getId())
                .shipmentRequestId(fee.getShipmentRequestId())
                .sourceBranchId(fee.getSourceBranchId())
                .hufAmount(fee.getHufAmount())
                .calculatedFee(fee.getCalculatedFee())
                .status(fee.getStatus())
                .createdAt(fee.getCreatedAt())
                .approvedAt(fee.getApprovedAt())
                .build();
    }
}

package hu.puzzleir.valuta.dto.shipment;

import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentRequestResponseDto {
    private UUID id;
    private String requestNumber;
    private UUID companyId;
    private String serialPrefix;
    private Long serialNumber;

    private UUID fromBranchId;
    private String fromBranchCode;
    private String fromBranchName;
    private UUID toBranchId;
    private String toBranchCode;
    private String toBranchName;

    private Long requestedById;
    private String requestedByWorkerName;
    private ShipmentRequestStatus status;
    private LocalDate requestDate;
    private LocalDate deliveryDate;
    private String notes;
    private String carrierName;
    private String sealNumber;
    private String rejectionReason;
    private Long rejectedByWorkerId;
    private String rejectedByWorkerName;
    private Long cancelledByWorkerId;
    private String cancelledByWorkerName;
    private LocalDateTime cancelledAt;
    private LocalDateTime createdAt;
    private List<ShipmentRequestItemResponseDto> items;

    // Frontend-kompatibilis aliasok a korábbi ShipmentRequest interface-hez.
    private UUID requestingBranchId;
    private String requestingBranchName;
    private UUID targetBranchId;
    private String targetBranchName;
    private ShipmentRequestStatus requestStatus;
    private LocalDate requestedDeliveryDate;
    private Long requestedByWorkerId;
    private LocalDateTime requestedAt;
    private Boolean staleForDelivery;
    private Integer staleThresholdHours;
}

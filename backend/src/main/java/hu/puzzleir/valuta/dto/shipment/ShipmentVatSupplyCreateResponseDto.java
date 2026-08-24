package hu.puzzleir.valuta.dto.shipment;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentVatSupplyCreateResponseDto {

    private ShipmentRequestResponseDto shipment;
    private ShipmentVatSupplyDto vatSupply;
}

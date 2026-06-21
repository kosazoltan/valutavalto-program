package hu.puzzleir.valuta.dto.shipment;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentRequestItemResponseDto {
    private UUID id;
    private Long currencyId;
    private BigDecimal requestedAmount;
    private BigDecimal approvedAmount;
    private BigDecimal deliveredAmount;
    private BigDecimal appliedRate;
    private BigDecimal hufValue;
}

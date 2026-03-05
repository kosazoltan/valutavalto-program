package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Szállítmánykérés tétel entity.
 */
@Entity
@Table(name = "shipment_request_item")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ShipmentRequestItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipment_request_id", nullable = false)
    @JsonIgnore
    private ShipmentRequest shipmentRequest;

    @Column(name = "currency_id", nullable = false)
    private Long currencyId;

    @Column(name = "requested_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal requestedAmount;

    @Column(name = "approved_amount", precision = 15, scale = 2)
    private BigDecimal approvedAmount;

    @Column(name = "delivered_amount", precision = 15, scale = 2)
    private BigDecimal deliveredAmount;
}

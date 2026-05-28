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

    /**
     * D követelmény (Bali Henriett 2026-05-27): a tétel rögzítésekor beemelt elszámoló
     * árfolyam (J = ExchangeRate.officialRate). Audit-megőrzés — utólagos árfolyam-változás
     * nem írja felül. Nullable a backward-compat miatt (régi szállítmányok rate nélkül).
     */
    @Column(name = "applied_rate", precision = 18, scale = 6)
    private BigDecimal appliedRate;

    /**
     * D követelmény: forintosított érték = {@code requestedAmount * appliedRate}, HUF kerekítve.
     * A service számolja a save-kor (RoundHuf alapján), a felhasználó nem írja kézzel.
     */
    @Column(name = "huf_value", precision = 18, scale = 2)
    private BigDecimal hufValue;
}
